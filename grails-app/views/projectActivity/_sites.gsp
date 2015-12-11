<div id="pActivitySites" class="well">

    <!-- ko foreach: projectActivities -->
    <!-- ko if: current -->
    <div class="row-fluid">
        <div class="span10 text-left">
            <h2 class="strong">Step 5 of 6 - Specify the area or places where the survey will be undertaken</h2>
        </div>
        <div class="span2 text-right">
            <g:render template="../projectActivity/status"/>
        </div>
    </div>

    <g:render template="/projectActivity/warning"/>

    <g:render template="/projectActivity/unpublishWarning"/>

    <div class="row-fluid">
        <div class="span12 text-left">
            <p>You can constrain the survey to a particular geographic area and/or to particular pre-determined sites.</p>
        </div>
    </div>

    <div class="row-fluid">

        <div class="span12 text-left">
            <div class="btn-group btn-group-justified">
                <a class="btn btn-xs btn-default" data-bind="attr:{href: transients.siteCreateUrl}">Add new site</a>
                <a class="btn btn-xs btn-default" data-bind="attr:{href: transients.siteSelectUrl}">Choose existing sites</a>
                <a class="btn btn-xs btn-default" data-bind="attr:{href: transients.siteUploadUrl}">Upload locations from shapefile</a>
            </div>
        </div>

    </div>

    </br>

    <div class="row-fluid">

        <div class="span6">
            <table class="table table-bordered" style="background-color: white">
                <thead>
                <tr>
                    <th class="text-left">Sites associated with this survey: <span class="req-field"></span></th>
                </tr>
                </thead>

                <tbody>
                <!-- ko foreach: sites -->
                <tr data-bind="visible: added()">
                    <td>
                        <a class="btn-link" target="_blank" data-bind="attr:{href: siteUrl}, text: name"></a>
                        <button class="btn-link pull-right" data-bind="click: removeSite"  title="Remove this site from survey">
                            <span class="icon-remove"></span>
                        </button>

                    </td>
                </tr>
                <!-- /ko -->
                </tbody>

            </table>
        </div>

        <div class="span6">
            <table class="table table-bordered" style="background-color: white">
                <thead>
                <tr>
                    <th>Sites associated with this project:</th>
                </tr>
                </thead>

                <tbody>
                <!-- ko foreach: sites -->
                <tr data-bind="visible: !added()">
                    <td>
                        <a class="btn-link" target="_blank" data-bind="attr:{href: siteUrl}, text: name"></a>
                        <button class="btn-link pull-right" data-bind="click: addSite" title="Add this site to survey">
                            <span class="icon-plus"></span>
                        </button>
                    </td>
                </tr>
                <!-- /ko -->
                </tbody>

            </table>
        </div>

    </div>

    </br>
    <!--
    Not supported.
    <div class="row-fluid">

        <div class="span12">
            <p>
                <input type="checkbox" data-bind="checked: restrictRecordToSites"/> Restrict record locations to the selected survey sites
            </p>
        </div>

    </div>
    -->
    <!-- /ko -->
    <!-- /ko -->
</div>

<!-- ko foreach: projectActivities -->
    <!-- ko if: current -->
    <div class="row-fluid">
        <div class="span12">
            <button class="btn-primary btn btn-small block" data-bind="click: $parent.saveSites, disable: !transients.saveOrUnPublishAllowed()"><i class="icon-white  icon-hdd" ></i>  Save </button>
            <button class="btn-primary btn btn-small block" data-bind="showTabOrRedirect: {url:'', tabId: '#survey-form-tab'}"><i class="icon-white icon-chevron-left" ></i>Back</button>
            <button class="btn-primary btn btn-small block" data-bind="showTabOrRedirect: {url:'', tabId: '#survey-publish-tab'}">Next <i class="icon-white icon-chevron-right" ></i></button>
        </div>
    </div>
    <!-- /ko -->
<!-- /ko -->