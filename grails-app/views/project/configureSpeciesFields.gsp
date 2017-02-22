<%@ page import="au.org.ala.biocollect.DateUtils; grails.converters.JSON; org.codehaus.groovy.grails.web.json.JSONArray" contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${hubConfig.skin}"/>
    <title>Configure species fields | Biocollect</title>
    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/jstimezonedetect/1.0.4/jstz.min.js"></script>
    <r:script disposition="head">
    var fcConfig = {
        serverUrl: "${grailsApplication.config.grails.serverURL}",
        projectViewUrl: "${createLink(controller: 'project', action: 'index')}/",
        projectUpdateUrl:"${createLink(action:'ajaxUpdate', id:project.projectId)}",
        addNewSpeciesListsUrl: "${createLink(controller: 'projectActivity', action: 'ajaxAddNewSpeciesLists', params: [projectId:project.projectId])}",
        speciesProfileUrl: "${createLink(controller: 'proxy', action: 'speciesProfile')}",
        speciesListUrl: "${createLink(controller: 'search', action: 'searchSpeciesList')}",
        speciesListsServerUrl: "${grailsApplication.config.lists.baseURL}",
        speciesSearchUrl: "${createLink(controller: 'search', action: 'species')}",
        getSingleSpeciesUrl : "${createLink(controller: 'projectActivity', action: 'getSingleSpecies', params: [id: '7d452be4-fd13-4a3e-8942-4b56645bdc91'])}",
        speciesSearch: "${createLink(controller: 'search', action: 'searchSpecies', params: [id: '7d452be4-fd13-4a3e-8942-4b56645bdc91', limit: 10])}"
        },
        here = document.location.href;
    </r:script>
    <r:require modules="knockout,jqueryValidationEngine,speciesFieldsSettings,projectSpeciesFieldsConfiguration"/>

</head>
<body>
<div class="container-fluid validationEngineContainer" id="validation-container">
    <g:if test="${!error}">
        <div id="koActivityMainBlock">
            <ul class="breadcrumb">
                <li><g:link controller="home">Home</g:link> <span class="divider">/</span></li>
                <g:if test="${project}">
                    <li><a data-bind="click:goToProject" class="clickable">Project</a> <span class="divider">/</span></li>
                </g:if>
                <li class="active">Configure species fields</li>
            </ul>
            <div class="row-fluid">
                <div class="header-text">
                    <h2><g:if test="${project}">
                        ${project.name?.encodeAsHTML()}
                    </g:if></h2>

                </div>
            </div>

            <!-- ko ifnot: surveysToConfigure().length > 0 -->
                <div class="row-fluid">
                    <div class="welll">
                        <div class="span8 title-attribute">
                            <h4><g:message code="project.survey.species.noSpeciesInProject"/></h4>
                        </div>
                    </div>
                </div>
            <!-- /ko -->
            <!-- ko if: surveysToConfigure().length > 0 -->
                <div class="row-fluid title-block well input-block-level">
                    <div class="space-after">
                        <p/>
                        Each activity has a type. If the different activity types have species fields, they must be configured here.
                        <p/>
                        It is also possible to set a species field default configuration that can be reused in each species field.
                        <p/>
                        If only one species field is available across all activity types for this project then only the Default Configuration will be available.
                        <p/>
                        If no species fields are available for this project then this screen configuration can be skipped.
                    </div>
                </div>
                <div class="well">
                    <h4><g:message code="project.survey.species.defaultConfiguration"/></h4>
                    <div class="row-fluid">
                        <div class="span8">
                            <div class="row-fluid">
                                <div class="span4 text-right">
                                    <label class="control-label" for="defaultInputSettings"><g:message code="project.survey.species.settings"/>
                                        <a href="#" class="helphover" data-bind="popover: {title:'<g:message code="project.survey.species.settings"/>', content:'<g:message code="project.survey.species.settings.content"/>'}">
                                            <i class="icon-question-sign"></i>
                                        </a>
                                    </label>
                                </div>
                                <div class="span8">
                                    <div class="controls">
                                        <span class="req-field" data-bind="tooltip: {title:species().transients.inputSettingsTooltip()}">
                                            <input id="defaultInputSettings" type="text" class="input-large" data-bind="disable: true, value: species().transients.inputSettingsSummary"> </input>
                                        </span>
                                        <a target="_blank" class="btn btn-link" data-bind="click: function() { showSpeciesConfiguration(species(), 'Default Configuration') }" ><small><g:message code="project.survey.species.configure"/></small></a>
                                    </div>
                                </div>
                            </div>
                            <div class="row-fluid">
                                <div class="span4 text-right">
                                    <label class="control-label" for="defaultSpeciesDisplayFormat"><g:message code="project.survey.species.displayAs"/>
                                        <a href="#" class="helphover" data-bind="popover: {title:'<g:message code="project.survey.species.displayAs"/>', content:'<g:message code="project.survey.species.displayAs.content"/>'}">
                                            <i class="icon-question-sign"></i>
                                        </a>
                                    </label>
                                </div>
                                <div class="span6">
                                    <div class="controls">
                                        <select id="defaultSpeciesDisplayFormat" data-bind="options: transients.availableSpeciesDisplayFormat, optionsText:'name', optionsValue:'id', value:  species().speciesDisplayFormat">
                                        </select>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- ko if: surveysToConfigure().length > 1 -->
                    <div class="well">
                    <h4><g:message code="project.survey.species.configureSpeciesFields"/></h4>
                    <div class="row-fluid">
                        <div class="span2 text-left">
                            <label class="control-label"><g:message code="project.survey.species.activityType"/>
                                <a href="#" class="helphover" data-bind="popover: {title:'<g:message code="project.survey.species.activityType"/>', content:'<g:message code="project.survey.species.activityType.content"/>'}">
                                    <i class="icon-question-sign"></i>
                                </a>
                            </label>
                        </div>
                        <div class="span2 text-left">
                            <label class="control-label"><g:message code="project.survey.species.fieldName"/>
                                <a href="#" class="helphover" data-bind="popover: {title:'<g:message code="project.survey.species.fieldName"/>', content:'<g:message code="project.survey.species.fieldName.content"/>'}">
                                    <i class="icon-question-sign"></i>
                                </a>
                            </label>
                        </div>
                        <div class="span4 text-left">
                            <label class="control-label"><g:message code="project.survey.species.settings"/>
                                <a href="#" class="helphover" data-bind="popover: {title:'<g:message code="project.survey.species.settings"/>', content:'<g:message code="project.survey.species.settings.content"/>'}">
                                    <i class="icon-question-sign"></i>
                                </a>
                            </label>
                        </div>
                        <div class="span4 text-left">
                            <label class="control-label"><g:message code="project.survey.species.displayAs"/>
                                <a href="#" class="helphover" data-bind="popover: {title:'<g:message code="project.survey.species.displayAs"/>', content:'<g:message code="project.survey.species.displayAs.content"/>'}">
                                    <i class="icon-question-sign"></i>
                                </a>
                            </label>
                        </div>
                    </div>

                    <!-- ko  foreach: surveysToConfigure() -->
                        <div class="row-fluid">
                            <div class="span2 text-left">
                                <b data-bind="text: name() "></b>
                            </div>
                        </div>
                        %{--Specific field configuration entries if more than one species field in the form--}%

                        <!-- ko  foreach: speciesFields() -->
                        <div class="row-fluid">
                            <div class="span2 "></div>
                            <div class="span2 text-left">
                                <span data-bind="text: transients.fieldName "></span>
                            </div>
                            <div class="span4">
                                <span class="req-field" data-bind="tooltip: {title:config().transients.inputSettingsTooltip()}">
                                    <input type="text" class="input-large" data-bind="disable: true, value: config().transients.inputSettingsSummary"> </input>
                                </span>
                                <a target="_blank" data-bind="click: function() { $root.showSpeciesConfiguration(config(), transients.fieldName, $parentContext.$index, $index ) }" class="btn btn-link" ><small><g:message code="project.survey.species.configure"/></small></a>
                            </div>
                            <div class="span4 text-left">
                                <select data-bind="disable: config().type() == 'DEFAULT_SPECIES', options: $root.transients.availableSpeciesDisplayFormat, optionsText:'name', optionsValue:'id', value:  config().speciesDisplayFormat">
                                </select>
                            </div>
                        </div>
                        <!-- /ko -->
                    <!-- /ko -->
                </div>
                <!-- /ko -->
                <!-- ko if: surveysWithoutFields().length > 0 -->
                <div class="well">
                    <h4><g:message code="project.survey.species.activityTypesWithNoSpecies"/></h4>
                    <div class="row-fluid">
                        <ul>
                        <!-- ko  foreach: surveysWithoutFields() -->
                        <li>
                            <span data-bind="text: name()"></span>
                        </li>
                        <!-- /ko -->
                        </ul>
                    </div>
                </div>
                <!-- /ko -->
            <!-- /ko -->
            <div class="form-actions">
                <!-- ko if: surveysToConfigure().length > 0 -->
                    <button type="button" data-bind="click: save" class="btn btn-primary">Save changes</button>
                <!-- /ko -->
                <button type="button" id="cancel" class="btn">Cancel</button>
            </div>
            <!-- ko stopBinding: true -->
                <div  id="speciesFieldDialog" data-bind="template: {name:'speciesFieldDialogTemplate'}"></div>
            <!-- /ko -->

            <script type="text/html" id="speciesFieldDialogTemplate">
            <g:render template="/projectActivity/speciesFieldSettingsDialog"></g:render>
            </script>
        </div>
    </g:if>
    <g:else>
        <div class="welll container">
            <div class="span8 title-attribute">
                <h4>${error?.encodeAsHTML()}</h4>
            </div>
        </div>
    </g:else>
    <g:if env="development">
        <hr/>
        <div class="expandable-debug">
            <h3>Debug</h3>
            <div>
                <!--h4>KO model</h4>
            <pre data-bind="text:ko.toJSON($root,null,2)"></pre-->
                <h4>Fields Config</h4>
                <pre>${fieldsConfig}</pre>
                <h4>Project</h4>
                %{--<pre>${project}</pre>--}%
            </div>
        </div>
    </g:if>
</div>

<!-- templates -->

<r:script>

    var returnTo = "${returnTo}";

    $(function(){



        $('.helphover').popover({animation: true, trigger:'hover'});

        $('#cancel').click(function () {
            document.location.href = returnTo;
        });


        var viewModel = new ProjectSpeciesFieldsConfigurationViewModel(
        <fc:modelAsJavascript model="${project}" />,
        <fc:modelAsJavascript model="${fieldsConfig}"/>
        );

        ko.applyBindings(viewModel,document.getElementById('koActivityMainBlock'));


    });

</r:script>
</body>
</html>