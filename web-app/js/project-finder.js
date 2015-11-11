/**
 * Created by Temi Varghese on 22/10/15.
 */
function ProjectFinder() {
    var self = this;
    /* holds all projects */
    var allProjects = [];

    /* holds current filtered list */
    var projects;

    /* pagination offset into the record set */
    var offset = 0;

    /* size of current filtered list */
    var total = 0;

    var searchTerm = '', perPage = 20, sortBy = 'nameSort', sortOrder = 1;
    // variable to not scroll to result when result is loaded for the first time.
    var firstTimeLoad = true;

    this.availableProjectTypes = new ProjectViewModel({}, false, []).transients.availableProjectTypes;

    this.sortKeys = [
        {name: 'Name', value: 'nameSort'},
        {name: 'Relevance', value: '_score'},
        {name: 'Organisation Name', value: 'organisationSort'},
        {name: 'Status', value: 'status'}
    ]

    /* window into current page */
    function pageVM() {
        this.pageProjects = ko.observableArray();
        this.availableProjectTypes = ko.observableArray(self.availableProjectTypes);
        this.projectTypes = ko.observable(['citizenScience','works','survey']);
        this.sortKeys = ko.observableArray(self.sortKeys);
        this.hideshow = function () {
            $("#pt-selectors").toggle();
        }
        this.download = function (obj, e) {
            var params = $.param(self.getParams(), true);
            var href = $(e.target).attr('href');
            var domain = href.slice(0, href.indexOf('?'))
            $(e.target).attr('href', domain + '?' + 'download=true&' + params)
            return true;
        }
    }

    /**
     * check if button has active flag
     * @param $button
     * @returns {boolean}
     */
    function isButtonChecked($button){
        return $button.hasClass('active')?true:false
    }

    /**
     * get values of data-value attribute for all active buttons
     * @param $button
     * @returns {Array}
     */
    function getActiveButtonValues($button){
        var result = [];
        $button.find('.active').each(function(index, it){
            result.push($(it).attr('data-value'));
        });
        return result
    }

    function uncheckButton($button){
        $button.removeClass('active');
        // if button group
        $button.find('.active').removeClass('active');
        return $button;
    }

    function checkButton($button, value, attribute){
        var attr = 'data-value' || attribute;
        $button.removeClass('active').find('button.active').removeClass('active');
        if($button.attr(attr)===value)
            $button.addClass('active')
        $button.find('['+attr+'='+value+']').addClass('active')
    }

    /**
     * bring the selected element to view by animation.
     * @param selector
     */
    function scrollToView(selector){
        $("html, body").animate({
            scrollTop: $(selector).offset().top
        })
    }

    var pageWindow = new pageVM();
    ko.applyBindings(pageWindow, document.getElementById('pt-table'));

    this.getParams = function () {
        var fq = [];
        var isSuitableForChildren = isButtonChecked($('#pt-search-children'));
        var isDIY = isButtonChecked($('#pt-search-diy'))
        var status = getActiveButtonValues($('#pt-status')) // active check field status
        var hasParticipantCost = isButtonChecked($('#pt-search-noCost')) // no cost
        var hasTeachingMaterials = isButtonChecked($('#pt-search-teach')) // teaching material
        var isMobile = isButtonChecked($('#pt-search-mobile')) // mobile uses links to find it out
        var difficulty = getActiveButtonValues($('#pt-search-difficulty'))
        var isCitizenScience = fcConfig.isCitizenScience,
            isWorks = false,
            isSurvey = false;
        var isUserPage = fcConfig.isUserPage || false;
        var organisationName = fcConfig.organisationName;

        sortBy = getActiveButtonValues($("#pt-sort"))
        perPage = getActiveButtonValues($("#pt-per-page"))

        if (fcConfig.isOrganisationPage) {
            var values = getActiveButtonValues($('#pt-search-projecttype'));
            for (var i in values) {
                switch (values[i]) {
                    case 'citizenScience':
                        isCitizenScience = true;
                        break;
                    case "survey":
                        isSurvey = true;
                        break;
                    case 'works':
                        isWorks = true;
                        break;
                }
            }
        }

        var params = {
            fq: fq,
            offset: offset,
            status: status,
            isCitizenScience: isCitizenScience,
            isWorks: isWorks,
            isSurvey: isSurvey,
            isUserPage: isUserPage,
            hasParticipantCost: hasParticipantCost,
            isSuitableForChildren: isSuitableForChildren,
            isDIY: isDIY,
            hasTeachingMaterials: hasTeachingMaterials,
            isMobile: isMobile,
            difficulty: difficulty,
            organisationName: organisationName,
            max: perPage, // page size
            sort: sortBy,
            q: $('#pt-search').val().toLowerCase()
        }

        return params;
    }

    /**
     * this is the function calling server with the latest query.
     */
    this.doSearch = function () {
        var params = self.getParams();
        window.location.hash = params.q;
        return $.ajax({
            url: fcConfig.projectListUrl,
            data: params,
            traditional: true,
            success: function (data) {
                var projectVMs = [];
                var organisation = fcConfig.organisation || []
                total = data.total;
                $.each(data.projects, function (i, project) {
                    projectVMs.push(new ProjectViewModel(project, false, organisation));
                });
                self.pago.init(projectVMs);
            },
            error: function () {
                console.error("Could not load project data.")
                console.log(arguments)
            }
        })
    }

    this.searchAndShowFirstPage = function () {
        self.pago.firstPage();
        return true
    }

    /*************************************************\
     *  Show filtered projects on current page
     \*************************************************/
    this.populateTable = function () {
        pageWindow.pageProjects(projects);
        pageWindow.pageProjects.valueHasMutated();
        self.showPaginator();
    }

    /** display the current size of the filtered list **/
    this.updateTotal = function () {
        $('#pt-resultsReturned').html("Found <strong>" + total + "</strong> " + (total == 1 ? 'project.' : 'projects.'));
    }

    /*************************************************\
     *  Pagination
     \*************************************************/
    /** build and append the pagination widget **/
    this.showPaginator = function () {
        if (total <= perPage) {
            // no pagination required
            $('div#pt-navLinks').html("");
            return;
        }
        var currentPage = Math.floor(offset / perPage) + 1;
        var maxPage = Math.ceil(total / perPage);
        var $ul = $("<ul></ul>");
        // add prev
        if (offset > 0)
            $ul.append('<li><a href="javascript:pago.prevPage();">&lt;</a></li>');
        for (var i = currentPage - 3, n = 0; i <= maxPage && n < 7; i++) {
            if (i < 1) continue;
            n++;
            if (i == currentPage)
                $ul.append('<li><a href="#" class="currentStep">' + i + '</a></li>');
            else
                $ul.append('<li><a href="javascript:pago.gotoPage(' + i + ');">' + i + '</a></li>');
        }
        // add next
        if ((offset + perPage) < total)
            $ul.append('<li><a href="javascript:pago.nextPage();">&gt;</a></li>');

        var $pago = $("<div class='pagination'></div>");
        $pago.append($ul);
        $('div#pt-navLinks').html($pago);
    }

    this.augmentVM = function (vm) {
        var x, urls = [];
        if (vm.urlWeb()) urls.push('<a href="' + vm.urlWeb() + '">Website</a>');
        for (x = "", docs = vm.transients.mobileApps(), i = 0; i < docs.length; i++)
            x += '&nbsp;<a href="' + docs[i].link.url + '"><img class="logo-small" src="' + docs[i].logo(fcConfig.logoLocation) + '"/></a>';
        if (x) urls.push("Mobile Apps&nbsp;" + x);
        for (x = "", docs = vm.transients.socialMedia(), i = 0; i < docs.length; i++)
            x += '&nbsp;<a href="' + docs[i].link.url + '"><img class="logo-small" src="' + docs[i].logo(fcConfig.logoLocation) + '"/></a>';
        if (x) urls.push("Social Media&nbsp;" + x);
        vm.transients.links = urls.join('&nbsp;&nbsp;|&nbsp;&nbsp;') || '';
        vm.transients.searchText = (vm.name() + ' ' + vm.aim() + ' ' + vm.description() + ' ' + vm.keywords() + ' ' + vm.transients.scienceTypeDisplay() + ' ' + vm.transients.locality + ' ' + vm.transients.state + ' ' + vm.organisationName()).toLowerCase();
        vm.transients.indexUrl = fcConfig.projectIndexBaseUrl + vm.transients.projectId;
        vm.transients.orgUrl = vm.organisationId() && (fcConfig.organisationBaseUrl + vm.organisationId());
        vm.transients.imageUrl = fcConfig.meritProjectLogo && vm.isMERIT() ? fcConfig.meritProjectLogo : vm.imageUrl();
        if (!vm.transients.imageUrl) {
            x = vm.primaryImages();
            if (x && x.length > 0) vm.transients.imageUrl = x[0].url;
        }
        return vm;
    }

    /* comparator for data projects */
    function comparator(a, b) {
        var va = a[sortBy](), vb = b[sortBy]();
        va = va ? va.toLowerCase() : '';
        vb = vb ? vb.toLowerCase() : '';
        if (va == vb && sortBy != 'name') { // sort on name
            va = a.name().toLowerCase();
            vb = b.name().toLowerCase();
        }
        return (va < vb ? -1 : (va > vb ? 1 : 0)) * sortOrder;
    }

    this.setTextSearchSettings = function(){
        checkButton($('#pt-sort '),'_score')
    }
    $("#pt-filter").on('statechange',function(){
        if($('#pt-filter').hasClass('active')){
            $('#pt-selectors').slideDown(400)
        } else {
            $('#pt-selectors').slideUp(400)
        }
    })
    $('#pt-search-link').click(function () {
        self.setTextSearchSettings();
        self.doSearch();
    });
    $('#pt-search').keypress(function (event) {
        if (event.which == 13) {
            event.preventDefault();
            self.setTextSearchSettings();
            self.doSearch();
        }
    });
    $('#pt-reset').click(function () {
        uncheckButton($('#pt-tags'));
        uncheckButton($('#pt-status'));
        uncheckButton($('#pt-search-difficulty'));
        checkButton($('#pt-sort'),'nameSort');
        checkButton($('#pt-per-page'),'20');
        $('#pt-search').val('');
        self.pago.firstPage();
    });
    // check for statechange event on all buttons in filter panel.
    $('#pt-searchControls button').on('statechange', self.searchAndShowFirstPage);

    pago = this.pago = {
        init: function (projs) {
            var hasPrograms = false;
            projects = allProjects = [];
            $.each(projs, function (i, project) {
                allProjects.push(self.augmentVM(project));
                if (project.associatedProgram()) hasPrograms = true;
            });

            self.populateTable();
            self.updateTotal();
            self.showPaginator();
        },
        gotoPage: function (pageNum) {
            offset = (pageNum - 1) * perPage;
            self.doSearch().done(function(){
                scrollToView("#pt-table");
            });
        },
        prevPage: function () {
            offset -= perPage;
            self.doSearch().done(function(){
                scrollToView("#pt-table");
            });;
        },
        nextPage: function () {
            offset += perPage;
            self.doSearch().done(function(){
                scrollToView("#pt-table");
            });;
        },
        firstPage: function () {
            offset = 0;
            self.doSearch().done(function(){
                scrollToView("#pt-table");
            });;
        }
    }

    $('#pt-search').val(window.location.hash.replace('#','')).focus()
    this.doSearch();
}