package au.org.ala.biocollect.merit
import au.org.ala.biocollect.EmailService
import grails.converters.JSON

class ProjectService {

    WebService webService
    def grailsApplication
    SiteService siteService
    ActivityService activityService
    DocumentService documentService
    UserService userService
    MetadataService metadataService
    SettingService settingService
    EmailService emailService

    /**
     * Check if a project already exists with the specified name.
     *
     * @param projectName The name to check
     * @param id The ID of the project being edited, to exclude it from the check. Leave null if creating a new project
     * @return True if no other active project exists with the same name
     */
    boolean checkProjectName(String projectName, String id) {
        def results = webService.getJson("${grailsApplication.config.ecodata.service.url}/project/findByName?projectName=${URLEncoder.encode(projectName, "utf-8")}", 30000, true)

        results?.isEmpty() || (results?.size() == 1 && id == results[0]?.projectId)
    }

    def list(brief = false, citizenScienceOnly = false) {
        def params = brief ? '?brief=true' : ''
        if (citizenScienceOnly) params += (brief ? '&' : '?') + 'citizenScienceOnly=true'
        def resp = webService.getJson(grailsApplication.config.ecodata.service.url + '/project/' + params, 30000)
        resp.list
    }

    def listMyProjects(userId) {
        def resp = webService.getJson(grailsApplication.config.ecodata.service.url + '/permissions/getAllProjectsForUserId?id=' + userId, 30000)
        resp
    }

    def get(id, levelOfDetail = "", includeDeleted = false) {

        def params = '?'

        params += levelOfDetail ? "view=${levelOfDetail}&" : ''
        params += "includeDeleted=${includeDeleted}"
        webService.getJson(grailsApplication.config.ecodata.service.url + '/project/' + id + params)
    }

    def getRich(id) {
        get(id, 'rich')
    }

    def getActivities(project) {
        def list = []
        project.sites.each { site ->
            siteService.get(site.siteId)?.activities?.each { act ->
                list << activityService.constructName(act)
            }
        }
        list
    }

    /**
     * Creates a new project and adds the user as a project admin.
     */
    def create(props) {
        def activities = props.remove('selectedActivities')

        // create a project in ecodata
        Map result = webService.doPost(grailsApplication.config.ecodata.service.url + '/project/', props)

        String subject
        String body
        if (result?.resp?.projectId) {
            String projectId = result.resp.projectId
            // Add the user who created the project as an admin of the project
            userService.addUserAsRoleToProject(userService.getUser().userId, projectId, RoleService.PROJECT_ADMIN_ROLE)
            if (activities) {
                settingService.updateProjectSettings(projectId, [allowedActivities: activities])
            }

            subject = "New project ${props.name} was created by ${userService.currentUserDisplayName}"
            body = "User ${userService.currentUserId} (${userService.currentUserDisplayName}) has successfully created a new project ${props.name} with id ${projectId}"
        } else {
            subject = "An error occurred while creating a new project"
            body = "User ${userService.currentUserId} (${userService.currentUserDisplayName}) attempted to create a new project ${props.name}, but an error occurred during creation: ${result.error}."
        }

        emailService.sendEmail(subject, body, ["${grailsApplication.config.biocollect.support.email.address}"])

        result
    }

    def update(id, body, boolean skipEmailNotification = false) {
        def result = webService.doPost(grailsApplication.config.ecodata.service.url + '/project/' + id, body)

        if (!skipEmailNotification) {
            String projectName = get(id, "brief")?.name
            String subject = "Project ${projectName ?: id} was updated by ${userService.currentUserDisplayName}"
            String emailBody = "User ${userService.currentUserId} (${userService.currentUserDisplayName}) has updated project ${projectName ?: id}"
            emailService.sendEmail(subject, emailBody, ["${grailsApplication.config.biocollect.support.email.address}"])
        }

        result
    }

    /**
     * This does a 'soft' delete. The record is marked as inactive but not removed from the DB.
     * @param id the record to delete
     * @return the returned status
     */
    def delete(id) {
        def response = webService.doDelete(grailsApplication.config.ecodata.service.url + '/project/' + id)

        String projectName = get(id, "brief")?.name
        String subject = "Project ${projectName ?: id} was deleted by ${userService.currentUserDisplayName}"
        String emailBody = "User ${userService.currentUserId} (${userService.currentUserDisplayName}) has deleted project ${projectName ?: id}"
        emailService.sendEmail(subject, emailBody, ["${grailsApplication.config.biocollect.support.email.address}"])

        response
    }

    /**
     * This does a 'hard' delete. The record is removed from the DB.
     * @param id the record to destroy
     * @return the returned status
     */
    def destroy(id) {
        String subject = "Project ${id} was hard-deleted by ${userService.currentUserDisplayName}"
        String emailBody = "User ${userService.currentUserId} (${userService.currentUserDisplayName}) has hard-deleted project ${id}"
        emailService.sendEmail(subject, emailBody, ["${grailsApplication.config.biocollect.support.email.address}"])

        webService.doDelete(grailsApplication.config.ecodata.service.url + '/project/' + id + '?destroy=true')
    }

    /**
     * Retrieves a summary of project metrics (including planned output targets)
     * and groups them by output type.
     * @param id the id of the project to get summary information for.
     * @return TODO document this structure.
     */
    def summary(String id) {
        def scores = webService.getJson(grailsApplication.config.ecodata.service.url + '/project/projectMetrics/' + id)

        def scoresWithTargetsByOutput = [:]
        def scoresWithoutTargetsByOutputs = [:]
        if (scores && scores instanceof List) {
            // If there was an error, it would be returning a map containing the error.
            // There are some targets that have been saved as Strings instead of numbers.
            scoresWithTargetsByOutput = scores.grep { it.target && it.target != "0" }.groupBy { it.score.outputName }
            scoresWithoutTargetsByOutputs = scores.grep { it.results && (!it.target || it.target == "0") }.groupBy {
                it.score.outputName
            }
        }
        [targets: scoresWithTargetsByOutput, other: scoresWithoutTargetsByOutputs]
    }

    def search(params) {
        webService.doPost(grailsApplication.config.ecodata.service.url + '/project/search', params)
    }

    /**
     * Get the list of users (members) who have any level of permission for the requested projectId
     *
     * @param projectId
     * @return
     */
    def getMembersForProjectId(projectId) {
        def url = grailsApplication.config.ecodata.service.url + "/permissions/getMembersForProject/${projectId}"
        webService.getJson(url)
    }

    /**
     * Does the current user have permission to administer the requested projectId?
     * Checks for the ADMIN role in CAS and then checks the UserPermission
     * lookup in ecodata.
     *
     * @param userId
     * @param projectId
     * @return boolean
     */
    def isUserAdminForProject(userId, projectId) {
        def userIsAdmin

        if (userService.userIsSiteAdmin()) {
            userIsAdmin = true
        } else {
            def url = grailsApplication.config.ecodata.service.url + "/permissions/isUserAdminForProject?projectId=${projectId}&userId=${userId}"
            userIsAdmin = webService.getJson(url)?.userIsAdmin  // either will be true or false
        }

        userIsAdmin
    }

    /**
     * Does the current user have caseManager permission for the requested projectId?
     *
     * @param userId
     * @param projectId
     * @return
     */
    def isUserCaseManagerForProject(userId, projectId) {
        def url = grailsApplication.config.ecodata.service.url + "/permissions/isUserCaseManagerForProject?projectId=${projectId}&userId=${userId}"
        webService.getJson(url)?.userIsCaseManager // either will be true or false
    }

    /**
     * Does the current user have permission to edit the requested projectId?
     * Checks for the ADMIN role in CAS and then checks the UserPermission
     * lookup in ecodata.
     *
     * @param userId
     * @param projectId
     * @return boolean
     */
    def canUserEditProject(userId, projectId, merit = true) {
        def userCanEdit

        if (userService.userIsSiteAdmin()) {
            userCanEdit = true
        } else {
            def url = grailsApplication.config.ecodata.service.url + "/permissions/canUserEditProject?projectId=${projectId}&userId=${userId}"
            userCanEdit = webService.getJson(url)?.userIsEditor ?: false
        }

        // Merit projects are not allowed to be edited.
        if (userCanEdit && merit) {
            def project = get(projectId, 'brief')
            def program = metadataService.programModel(project.associatedProgram)
            userCanEdit = !program?.isMeritProgramme
        }

        userCanEdit
    }

    /**
     * Does the current user have permission to edit the requested projectId?
     * Checks for the ADMIN role in CAS and then checks the UserPermission
     * lookup in ecodata.
     *
     * @param userId
     * @param projectId
     * @return boolean
     */
    Map canUserEditProjects(String userId, String projectId) throws SocketTimeoutException, Exception {
        def isAdmin
        Map permissions = [:], response

        if (userService.userIsAlaAdmin()) {
            isAdmin = true
        }

        def url = grailsApplication.config.ecodata.service.url + "/permissions/canUserEditProjects"
        Map params = [projectIds:projectId,userId:userId]
        response = webService.doPostWithParams(url, params)

        if(response.error){
            if(response.error.contains('Timed out')){
                throw new SocketTimeoutException(response.error)
            } else {
                throw new Exception(response.error)
            }
        }

        if(isAdmin){
            response?.resp?.each{ key, value ->
                if(value != null){
                    permissions[key] = true
                } else {
                    permissions[key] = null;
                }
            }
        } else {
            permissions = response.resp;
        }

        permissions
    }

    /**
     * Can user edit bio collect activity
     * @param userId the user to test.
     * @param the activity to test.
     */
    def canUserEditActivity(String userId, Map activity) {
        boolean userCanEdit = false
        if (userService.userIsSiteAdmin()) {
            userCanEdit = true
        } else {
            String url = grailsApplication.config.ecodata.service.url + "/permissions/canUserEditProject?projectId=${activity?.projectId}&userId=${userId}"
            boolean userIsProjectEditor = webService.getJson(url)?.userIsEditor ?: false
            if (userIsProjectEditor && activity?.userId == userId) {
                userCanEdit = true
            }
        }
        userCanEdit
    }

    /**
     * Does the current user have permission to view details of the requested projectId?
     * @param userId the user to test.
     * @param the project to test.
     */
    def canUserViewProject(userId, projectId) {

        def userCanView
        if (userService.userIsSiteAdmin() || userService.userHasReadOnlyAccess()) {
            userCanView = true
        } else {
            userCanView = canUserEditProject(userId, projectId)
        }
        userCanView
    }


    /**
     * Returns the programs model for use by a particular project.  At the moment, this method just delegates to the metadataservice,
     * however a per organisation programs model is something being discussed.
     */
    def programsModel() {
        metadataService.programsModel()
    }

    /**
     * Returns a filtered list of activities for use by a project
     */
    public List activityTypesList(String projectId) {
        def projectSettings = settingService.getProjectSettings(projectId)
        def activityTypes = metadataService.activityTypesList()

        def allowedActivities = activityTypes
        if (projectSettings?.allowedActivities) {

            allowedActivities = []
            activityTypes.each { category ->
                def matchingActivities = []
                category.list.each { nameAndDescription ->
                    if (nameAndDescription.name in projectSettings.allowedActivities) {
                        matchingActivities << nameAndDescription
                    }
                }
                if (matchingActivities) {
                    allowedActivities << [name: category.name, list: matchingActivities]
                }
            }

        }

        allowedActivities
    }


    public JSON userProjects(UserDetails user) {
        if (user) {
            def projects = userService.getProjectsForUserId(8443)
            def starredProjects = userService.getStarredProjectsForUserId(8443)
            ['active': projects, 'starred': starredProjects] as JSON;
        } else {
            [:] as JSON
        }
    }

    /**
     * get image documents from ecodata
     * @param projectId
     * @param payload
     * @return
     */
    Map listImages(Map payload) throws SocketTimeoutException, Exception{
        Map response
        payload.type = 'image';
        payload.role = ['surveyImage']
        String url = grailsApplication.config.ecodata.service.url + '/document/listImages'
        response = webService.doPost(url, payload)
        if(response.resp){
            return response.resp;
        } else  if(response.error){
            if(response.error.contains('Timed out')){
                throw new SocketTimeoutException(response.error)
            } else {
                throw  new Exception(response.error);
            }
        }
    }

    /**
     * calls ecodata webservice to import scistarter projects
     * @return Interger - number of imported projects.
     * @throws SocketTimeoutException
     * @throws Exception
     */
    Map importSciStarterProjects() throws SocketTimeoutException, Exception{
        String url = "${grailsApplication.config.ecodata.service.url}/project/importProjectsFromScistarter";
        Map response = webService.doGet(url, [:]);
        if(response.resp && response.resp.count != null){
            return response.resp
        } else {
            if(response.error.contains('Timed out')){
                throw new SocketTimeoutException(response.error)
            } else {
                throw  new Exception(response.error);
            }
        }
    }
}
