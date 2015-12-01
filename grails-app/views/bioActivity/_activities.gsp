<!-- ko stopBinding: true -->
<div id="survey-all-activities-and-records-content">
    <div id="data-result-placeholder"></div>
    <g:render template="../bioActivity/search"/>
    <div class="row-fluid">
        <div class="span12">
            <div class="span3 text-left well">
                <!-- ko if: activities().length > 0 -->
                <g:render template="../bioActivity/facets"/>
                <!-- /ko -->
            </div>

            <div class="span9 text-left">
                <ul class="nav nav-tabs" id="tabDifferentViews">
                    <li class="active"><a href="#recordVis" data-toggle="tab">Records</a></li>
                    <li class=""><a href="#mapVis" id="dataMapTab" data-toggle="tab"
                                    onclick="drawMapOnTabClick()">Map</a></li>
                </ul>
                <div class="tab-content">
                    <div class="tab-pane active" id="recordVis">
                        <!-- ko if: activities().length > 0 -->
                        <div class="well">
                            <h3 class="text-left">Found <span data-bind="text: total()"></span> record<span
                                    data-bind="if: total() >= 2">s</span></h3>
                            <g:render template="../shared/pagination"/>
                            <!-- ko foreach : activities -->
                            <div class="row-fluid">
                                <div class="span12">
                                    <div data-bind="attr:{class: embargoed() ? 'searchResultSection locked' : 'searchResultSection'}">

                                        <div class="span9 text-left">
                                            <div>
                                                <h4>
                                                    <!-- ko if: embargoed() -->
                                                    <a href="#" class="helphover"
                                                       data-bind="popover: {title:'Access to the record is restricted to non-project members', content:'Embargoed until : ' + moment(embargoUntil()).format('DD/MM/YYYY')}">
                                                        <span class="icon-lock"></span>
                                                    </a>
                                                    <!--/ko -->
                                                    Survey name:
                                                    <a data-bind="attr:{'href': transients.viewUrl}">
                                                        <span data-bind="text: name"></span>
                                                    </a>
                                                </h4>
                                            </div>

                                            <div class="row-fluid">
                                                <div class="span12">
                                                    <div class="span7">
                                                        <div>
                                                            <h6>Project name: <a
                                                                    data-bind="attr:{'href': projectUrl()}"><span
                                                                        data-bind="text: projectName"></span></a></h6>
                                                        </div>

                                                        <div>
                                                            <h6>Submitted by: <span
                                                                    data-bind="text: ownerName"></span> on <span
                                                                    data-bind="text: lastUpdated.formattedDate"></span>
                                                            </h6>
                                                        </div>
                                                    </div>

                                                    <div class="span5">
                                                        <!-- ko if : records().length > 0 -->
                                                        <div>
                                                            <h6>
                                                                Species :
                                                                <!-- ko foreach : records -->
                                                                <a target="_blank"
                                                                   data-bind="attr:{href: $root.transients.bieUrl + '/species/' + guid()}">
                                                                    <span data-bind="text: $index()+1"></span>. <span
                                                                        data-bind="text: name"></span>
                                                                </a>
                                                                <span data-bind="if: $parent.records().length != $index()+1">
                                                                    <b>|</b>
                                                                </span>
                                                                <!-- /ko -->
                                                            </h6>
                                                        </div>
                                                        <!-- /ko -->

                                                    </div>
                                                </div>

                                            </div>
                                        </div>

                                        <div class="span3 text-right">

                                            <!-- looks awkward to show view eye icon by itself. Users can view the survey by clicking the survey title.-->
                                            <div class="padding-top-0" data-bind="if: showCrud()">
                                                <span class="margin-left-1">
                                                    <a data-bind="attr:{'href': transients.viewUrl}"><i
                                                            class="fa fa-eye" title="View survey"></i></a>
                                                </span>
                                                <span class="margin-left-1" data-bind="visible: showAdd()">
                                                    <a data-bind="attr:{'href': transients.addUrl}"><i
                                                            class="fa fa-plus" title="Add survey"></i></a>
                                                </span>
                                                <span class="margin-left-1">
                                                    <a data-bind="attr:{'href': transients.editUrl}"><i
                                                            class="fa fa-edit" title="Edit survey"></i></a>
                                                </span>
                                                <span class="margin-left-1">
                                                    <a href="#" data-bind="click: $parent.delete"><i
                                                            class="fa fa-remove" title="Delete survey"></i></a>
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <!-- /ko -->
                            <div class="margin-top-2"></div>
                            <g:render template="../shared/pagination"/>
                            <!-- ko if : activities().length > 0 -->
                            <div class="row-fluid">
                                <div class="span12 pull-right">
                                    <div class="span12 text-right">
                                        <div><small class="text-right"><span
                                                class="icon-lock"></span> indicates that only project members can access the record.
                                        </small></div>
                                    </div>

                                </div>
                            </div>
                            <!-- /ko -->
                        </div>
                        <!-- /ko -->
                    </div>

                    <div class="tab-pane" id="mapVis">
                        <div id="recordOrActivityMap">

                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<!-- /ko -->
<r:script>
    var activitiesAndRecordsViewModel, alaMap, results;
    function initialiseData(view) {
        activitiesAndRecordsViewModel = new ActivitiesAndRecordsViewModel('data-result-placeholder', view)
        ko.applyBindings(activitiesAndRecordsViewModel, document.getElementById('survey-all-activities-and-records-content'));
        // listen to facet change event so that map can be updated.
        activitiesAndRecordsViewModel.selectedFilters.subscribe(generateMap)
        activitiesAndRecordsViewModel.searchTerm.subscribe(generateMap)
    }

    var mapId = "#recordOrActivityMap";
    var dataMap;
    var MAX_NUMBER_OF_TRIES = 6, counter = 0;
    var features, bounds, featureType = 'record';
    <!-- Only load the google map on page load if the containing div is visible. -->
    <!-- This resolves issues with loading the map when the user is on a different tab (zoom problems with the map). -->
    <!-- There is also a 'click' event listener for the About tab icon which will load the map when the user selects the About tab. -->
    $(window).load(loadMap);
    function loadMap() {
        if ($(mapId).is(':visible') && !alaMap) {
            generateMap();
        } else {
            // if the map container is not visible then try again. one reason it has not appeared is knockout because
            // knockout is still processing bindings
            counter < MAX_NUMBER_OF_TRIES?setTimeout(loadMap, 500):null;
            counter++;
        }
    }
    function generatePopup(projectLinkPrefix, projectId, projectName, orgName, siteLinkPrefix, siteId, siteName){
        var html = "<div class='projectInfoWindow'>";

        if (projectId && projectName) {
            html += "<div><i class='icon-home'></i> <a target='_blank' href='" +
                        projectLinkPrefix + projectId + "'>" +projectName + "</a></div>";
        }

        if(orgName !== undefined && orgName != ''){
            html += "<div><i class='icon-user'></i> Org name:" +orgName + "</div>";
        }

        html+= "<div><i class='icon-map-marker'></i> Site: <a target='_blank' href='" +siteLinkPrefix + siteId + "'>" + siteName + "</a></div>";
        return html;
    }
    function generateRecordPopup(projectLinkPrefix, projectId, projectName, speciesName, bieUrl){
        var html = "<div class='projectInfoWindow'>";

        if (projectId && projectName) {
            html += "<div><i class='icon-home'></i> <a target='_blank' href='" +
                        projectLinkPrefix + projectId + "'>" +projectName + "</a></div>";
        }

        if(speciesName){
            html += "<div><a target='_blank' href="+bieUrl+"><i class='icon-map-marker'></i>" +speciesName + "</a></div>";
        }

        return html;
    }
    function drawMapOnTabClick(){
        if(!alaMap){
            generateMap();
        } else {
            plotOnMap(features, bounds);
        }
    }
    function generateMap() {
        var searchTerm = activitiesAndRecordsViewModel.searchTerm() || '';
        var view = activitiesAndRecordsViewModel.view;
        var url =fcConfig.getRecordsForMapping + '?max=10000&searchTerm='+ searchTerm+'&view=' + view;
        var facetFilters = []
        ko.utils.arrayForEach(activitiesAndRecordsViewModel.selectedFilters(), function (term) {
            facetFilters.push(term.facetName() + ':' + term.term());
        });

        if (facetFilters && facetFilters.length > 0) {
            url += "&fq=" + facetFilters.join("&fq=");
        }

        $.getJSON(url, function(data) {
            results = data;
            generateDotsFromResult(data)
        }).error(function (request, status, error) {
            console.error("AJAX error", status, error);
        });
    }

    function generateDotsFromResult(data){
            features = [];
            var projectIdMap = {};
            bounds = new google.maps.LatLngBounds();
            var geoPoints = data;

            if (geoPoints.activities) {
                var projectLinkPrefix = "${createLink(controller: 'project')}/";
                var siteLinkPrefix = "${createLink(controller: 'site')}/";

                $.each(geoPoints.activities, function(index, activity) {
                    var projectId = activity.projectId
                    var projectName = activity.name
                    var siteName;
                    if(activity.sites && activity.sites.length){
                        siteName = activity.sites[0].name;
                    }

                    switch (featureType){
                        case 'record':
                        if (activity.records && activity.records.length > 0) {
                            $.each(activity.records, function(k, el) {
                                var point = {
                                    type: "dot",
                                    id: projectId,
                                    name: projectName,
                                    popup: generateRecordPopup(projectLinkPrefix,projectId,projectName,el.name, fcConfig.speciesPage + el.guid),
                                    latitude: el.coordinates[1],
                                    longitude: el.coordinates[0],
                                    color: '#BC2B03'
                                }

                                features.push(point);
                                bounds.extend(new google.maps.LatLng(point.latitude,point.longitude));
                            });
                        }
                        break;
                        case 'activity':
                            var point = {
                                    type: "dot",
                                    id: projectId,
                                    name: projectName,
                                    popup: generatePopup(projectLinkPrefix,projectId,projectName,undefined,siteLinkPrefix, activity.siteId, siteName),
                                    latitude: activity.coordinates[1],
                                    longitude: activity.coordinates[0],
                                    color: '#BC2B03'
                                }

                                features.push(point);
                                bounds.extend(new google.maps.LatLng(point.latitude,point.longitude));
                        break;
                    }
                });

                plotOnMap(features, bounds);
            }
    }

    function plotOnMap(features, bounds){
        if (!$(mapId).is(':visible')) {
            return
        }

        var mapData = {
            "zoomToBounds": true,
            "zoomLimit": 12,
            "highlightOnHover": false,
            "features": features
        }

        if(!alaMap){
            alaMap = new MapWithFeatures({
                    mapContainer: "recordOrActivityMap",
                    zoomToBounds:true,
                    scrollwheel: false,
                    zoomLimit:16,
                    featureService: "${createLink(controller: 'proxy', action: 'feature')}",
                    wmsServer: "${grailsApplication.config.spatial.geoserverUrl}"
                },
                mapData
            );
            createControls();
        } else {
            alaMap.clearFeatures();
            alaMap.load(features);
        }

        bounds && alaMap.map.fitBounds(bounds);
    }

    function createControls(){
            var homeControlDiv = document.createElement('div');
            addMapControls(homeControlDiv, alaMap.map);
            homeControlDiv.index = 2;
            alaMap.map.controls[google.maps.ControlPosition.BOTTOM_LEFT].push(homeControlDiv);
    }

    function addMapControls(controlDiv, map) {

        // Set CSS styles for the DIV containing the control
        // Setting padding to 5 px will offset the control
        // from the edge of the map
        controlDiv.style.padding = '5px';
        var html = $('#controlRecordsOrActivity').html();

        $(controlDiv).html(html)
        //// Setup the click event listeners
        $(controlDiv).find('.btn').click(getActivityOrRecords)
        getActivityOrRecords({
            target: $(controlDiv).find('.btn.active')[0]
        })
    }

    function getActivityOrRecords(e){
        var target = e.target;
        featureType = $(target).data('value');
        generateDotsFromResult(results);
    }
</r:script>
<script language="text/html" id="controlRecordsOrActivity">
<div class="btn-group mapControl" data-toggle="buttons-radio">
    <button type="button" class="btn btn-small btn-info active" data-value="record">Records</button>
    <button type="button" class="btn btn-small btn-info" data-value="activity">Activity</button>
</div>
</script>