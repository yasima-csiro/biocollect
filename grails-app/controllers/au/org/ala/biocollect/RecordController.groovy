package au.org.ala.biocollect

import au.org.ala.biocollect.merit.ActivityService
import au.org.ala.biocollect.merit.ProjectService
import au.org.ala.biocollect.merit.UserService
import grails.converters.JSON
import org.apache.http.HttpStatus

class RecordController {

    UserService userService
    ProjectActivityService projectActivityService
    RecordService recordService
    ActivityService activityService
    ProjectService projectService

    def ajaxList(){
        render listUserRecords(params) as JSON
    }

    def ajaxListForProject(String id){
        def model = [:]
        def query = [pageSize: params.max ?: 10,
                     offset: params.offset ?: 0,
                     sort: params.sort ?: 'lastUpdated',
                     order: params.order ?: 'desc']
        def results = recordService.listProjectRecords(id, query)
        String userId = userService.getCurrentUserId()
        boolean isAdmin = userId ? projectService.isUserAdminForProject(userId, id) : false

        results?.list?.each{
            it.pActivity = projectActivityService.get(it.projectActivityId)
            it.showCrud = isAdmin ?: (userId == it.userId)
        }
        model.records = results?.list
        model.total = results?.total

        render model as JSON
    }

    private def listUserRecords(params){
        def model = [:]
        def query = [pageSize: params.max ?: 10,
                     offset: params.offset ?: 0,
                     sort: params.sort ?: 'lastUpdated',
                     order: params.order ?: 'desc']
        def results = recordService.listUserRecords(userService.getCurrentUserId(), query)
        results?.list?.each{
            it.pActivity = projectActivityService.get(it.projectActivityId)
            it.showCrud = true
        }
        model.records = results?.list
        model.total = results?.total

        model
    }

    /**
     * Delete record for the given recordId
     * @param id recordId identifier
     * @return
     */
    def delete(String id) {
        def record = recordService.get(id)
        String userId = userService.getCurrentUserId()

        Map result
        if (!userId) {
            response.status = 401
            result = [status: 401, error: "Access denied: User has not been authenticated."]
        } else if (projectService.isUserAdminForProject(userId, record?.projectId) || activityService.isUserOwnerForActivity(userId, record?.activityId)) {
            def resp = recordService.delete(id)
            if (resp == HttpStatus.SC_OK) {
                result = [status: resp, text: 'deleted']
            } else {
                response.status = resp
                result = [status: resp, error: "Error deleting the survey, please try again later."]
            }
        } else {
            response.status = 401
            result = [status: 401, error: "Access denied: User is not an admin or owner of this record - ${id}"]
        }

        render result as JSON
    }

    def getGuidForOutputSpeciesIdentifier(String id) {
        def result = recordService.getForOutputIdentifier(id)
        render ([guid: result.guid ?: ''] as JSON)
    }

}
