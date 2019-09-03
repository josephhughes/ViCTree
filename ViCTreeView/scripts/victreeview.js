var ui;
var space = 3
var svg;
var highlighted_parent = null;
var distance = true;
var label = "Protein_GI"
var colours = ['rgb(166,206,227)', 'rgb(31,120,180)', 'rgb(178,223,138)', 'rgb(51,160,44)', 'rgb(251,154,153)', 'rgb(227,26,28)', 'rgb(253,191,111)', 'rgb(255,127,0)', 'rgb(202,178,214)', 'rgb(106,61,154)', 'rgb(255,255,153)', 'rgb(177,89,40)', 'rgb(141,211,199)', 'rgb(255,255,179)', 'rgb(190,186,218)', 'rgb(251,128,114)', 'rgb(128,177,211)', 'rgb(253,180,98)', 'rgb(179,222,105)', 'rgb(252,205,229)', 'rgb(217,217,217)', 'rgb(188,128,189)', 'rgb(204,235,197)', 'rgb(255,237,111)']


var Tree = function (distance_file, headers, label_file, json_tree, div) {
    this.json_tree = json_tree;
    this.div = div;
    this.species = distance_file;
    this.labels = label_file;
    this.headers = headers;
}

Tree.prototype.drawTree = function () {

    var parent = this;
    $(this.div).html("")

    $("#label_list").html("<a data-toggle='dropdown' class='dropdown-toggle ui-link' href='#''>Labels <b class='caret'></b></a>")

    var ObjUl = $('<ul class="dropdown-menu"></ul>');

    for (var i = 0; i < parent.headers.length; i++) {
        if (i == 0) {
            parent.label = parent.headers[i]
            $("<li><a href='#' class='ui-link label_list'>" + parent.headers[i] + " <span class='checked'> <i class='fa fa-check'></i></span> </a></li>").appendTo(ObjUl);
        } else {
            $("<li><a href='#' class='ui-link label_list'>" + parent.headers[i] + " <span class='checked'></span> </a></li>").appendTo(ObjUl);
        }

    }

    $("#label_list").append(ObjUl);

    $(".label_list").on('click', function () {
        changeLabel(this.text)
    })

    var margin = {
            top: 20,
            right: 120,
            bottom: 20,
            left: 20
        },
        width = 1260 - margin.right - margin.left,
        height = 800 - margin.top - margin.bottom;

    var i = 0,
        duration = 750;

    var tree = d3.layout.cluster()
        .size([height, width]);

    var projection = function (d) {
        return [d.y, d.x];
    }
    var path = function (pathData) {
        return "M" + pathData[0] + ' ' + pathData[1] + " " + pathData[2];
    }

    function diagonal(diagonalPath, i) {
        var source = diagonalPath.source,
            target = diagonalPath.target,
            midpointX = (source.x + target.x) / 2,
            midpointY = (source.y + target.y) / 2,
            pathData = [source, {
                x: target.x,
                y: source.y
            }, target];
        pathData = pathData.map(projection);
        return path(pathData)
    }

    function projection(x) {
        if (!arguments.length) return projection;
        projection = x;
        return diagonal;
    }

    function path(x) {
        if (!arguments.length) return path;
        path = x;
        return diagonal;
    }


    function scaleBranchLengths(nodes, w) {

        // Visit all nodes and adjust y pos width distance metric
        var visitPreOrder = function (root, callback) {
            callback(root)
            if (root.children) {
                for (var i = root.children.length - 1; i >= 0; i--) {

                    visitPreOrder(root.children[i], callback)
                }
                ;
            }
        }

        visitPreOrder(nodes[0], function (node) {
            // node.rootDist = (node.parent ? node.parent.rootDist : 0) + (node.data.length || 0)
            node.depth = (node.parent ? node.parent.depth : 0) + (parseFloat(node.attribute) || 0)

        })
        var depths = nodes.map(function (n) {
            return n.depth;
        });

        var yscale = d3.scale.linear()
            .domain([0, d3.max(depths)])
            .range([0, w]);
        visitPreOrder(nodes[0], function (node) {
            node.y = yscale(node.depth)
        })
        return yscale
    }


    $("#sort_ascending").on("click", function (e) {
        change_distance(true);
    });


    $("#sort_descending").on("click", function (e) {
        change_distance(false);
    });

    $('#change_tree').unbind('click');

    $("#change_tree").on("click", function (e) {

        if ($(".change_tree").hasClass("fa-align-justify")) {
            $(".change_tree").removeClass("fa-align-justify")
            $(".change_tree").addClass("fa-align-left")
        } else {
            $(".change_tree").addClass("fa-align-justify")
            $(".change_tree").removeClass("fa-align-left")
        }

        if (distance == true) {
            distance = false;
        } else {
            distance = true;
        }
        update(root);
    });


    $("#slider").slider({
        value: 0,
        min: 0,
        max: 100,
        step: 1,
        slide: function (event, ui) {
            $("#percentage").val(ui.value);
        }
    });
    $("#percentage").val($("#slider").slider("value"));

    $("#slider").slider({
        change: function (event, ui) {
            pathtohighlight(ui.value)
        }
    });

    $("#percentage").on("change", function () {
        $("#slider").slider({
            value: $("#percentage").val()
        })
    })

    function changeLabel(newLabel) {
        label = newLabel.replace(/\s+/g, '');

        $("#label_list .checked").each(function () {
            var self = this
            var select = $(self).parent().text().replace(/\s+/g, '')

            if (label == select) {
                $(self).html(" <i class='fa fa-check'></i>")
            } else {
                $(self).html("")
            }
        });

        update(root);
    }

    d3.select("#save_svg").on("click", function () {

        var html = d3.select("svg")
            .attr("version", 1.1)
            .attr("xmlns", "http://www.w3.org/2000/svg")
            .node().parentNode.innerHTML;
        /**
         *
         * @param data
         * @param name
         */

        dlText(html, "svg")

        function dlText(data, name) {
            download(data, name, "svg/plain");
        }


    });

    d3.select("#save_image").on("click", function () {
        jQuery("#canvas").html("")
        var canvas = document.getElementById('canvas');
        var context = canvas.getContext('2d');

        // do some drawing
        context.clearRect(0, 0, canvas.width, canvas.height);

        var html = d3.select("svg")
            .attr("version", 1.1)
            .attr("xmlns", "http://www.w3.org/2000/svg")
            .node().parentNode.innerHTML;
        var imgsrc = 'data:image/svg+xml;base64,' + btoa(html);
        var img = '<img src="' + imgsrc + '">';
        d3.select("#svgdataurl").html(img);


        var canvas = document.querySelector("canvas"),
            context = canvas.getContext("2d");


        var image = new Image;
        image.src = imgsrc;
        var canvasdata;
        image.onload = function () {
            context.drawImage(image, 0, 0);

            canvasdata = canvas.toDataURL("image/png");

            //var pngimg = '<img src="' + canvasdata + '">';
            //d3.select("#pngdataurl").html(pngimg);
            //
            //var a = document.createElement("a");
            //a.download = "sample.png";
            //a.href = canvasdata;
            //a.click();
            dlText(canvasdata, "image")

        };

        /**
         *
         * @param data
         * @param name
         */


        function dlText(data, name) {
            download(data, name, "image/png");
        }


    });


    function zoom() {
        svg.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");

        svg
            .attr("width", $(document).width())
            .attr("height", $(document).height())

    }


    var zoomListener = d3.behavior.zoom().scaleExtent([0.1, 3]).on("zoom", zoom);


    svg = d3.select(this.div).append("svg")
        .attr("width",  $(document).width())
        .attr("height",  $(document).height())
        .call(zoomListener)
        .append("g")
        .attr("transform", "translate("+margin.left+","+margin.top+")");

    svg.append("svg:clipPath").attr("id", "clipper")
        .append("svg:rect")
        .attr('id', 'clip-rect');


    var json_tree = this.json_tree
    d3.json(json_tree, function () {

        root = json_tree.json;
        root.x0 = height / 2;
        root.y0 = 0;

        function collapse(d) {
            if (d.children) {
                d._children = d.children;
                d._children.forEach(collapse);
                d.children = null;
            }
        }


        update(root);
    });


    d3.select(self.frameElement).style("height", "800px");

    function update(source) {
        // Compute the new tree layout.
        var nodes = tree.nodes(root),
            links = tree.links(nodes);

        nodes = addLabels(nodes)

        if (distance) {

            var yscale = scaleBranchLengths(nodes, width)
        }

        // Update the nodes…
        var node = svg.selectAll("g.node")
            .data(nodes, function (d) {
                return d.id || (d.id = ++i);
            });


        // Update the links…
        var link = svg.selectAll("path")
            .data(links, function (d) {
                return d.target.id;
            });

        // Enter any new links at the parent's previous position.
        link.enter()
            .append("path", "g")
            .style("fill", "none")
            .style("stroke", function (d) {
                if (d.source.highlighted == true) {
                    return "red"
                } else if (d.filtered == true) {
                    return d.colours;
                } else {
                    return "#ccc";
                }
            })
            .style("stroke-width", "1.5px")
            .attr("d", diagonal)
            .transition()
            .style("stroke", function (d, i) {
                if (d.target.highlighted == true) {
                    return "red"
                } else if (d.source.filtered == true) {
                    return d.source.colours;
                } else {
                    return "#ccc";
                }
            })
            .style("stroke-width", function (d, i) {
                if (d.target.highlighted == true) {
                    return "5px"
                } else {
                    return "1.5px";
                }
            })
            .duration(2000)
            .ease("linear")
            .attr("stroke-dashoffset", 0);

        // Transition links to their new position.
        link.transition()
            .duration(duration)
            .style("stroke", function (d, i) {
                if (d.target.highlighted == true) {
                    return "red"
                } else if (d.source.filtered == true) {
                    return d.source.colours;
                } else {
                    return "#ccc";
                }
            })
            .style("stroke-width", function (d, i) {
                if (d.target.highlighted == true) {
                    return "5px"
                } else {
                    return "1.5px";
                }
            })

            .attr("d", diagonal)

        // Transition exiting nodes to the parent's new position.
        link.exit().transition()
            .duration(duration)
            .attr("d", diagonal)
            .remove();


        // Enter any new nodes at the parent's previous position.


        var nodeEnter = node.enter().append("g")
            .attr("class", function (n) {
                if (n.children) {
                    if (n.depth == 0) {
                        return "root node"
                    } else {
                        return "inner node"
                    }
                } else {
                    return "leaf node"
                }
            })
            .attr("transform", function (d) {
                return "translate(" + d.y + "," + d.x + ")";
            })
            .attr("distance", function (d) {
                if (d.species) {

                } else if (d.children) {
                    var distance = findDistance(d)
                    d.distance = distance

                    return distance
                }

            });

        nodeEnter.append("circle")
            .attr("r", 1e-6)
            .style("stroke", "black")
            .style("stroke-width", "0.5px")
            .style("z-index", "999")
            .style("fill", function (d, i) {
                if (d.highlighted == true) {
                    return "red"
                } else if (d.colours) {
                    return d.colours;
                } else {
                    return d._children ? "lightsteelblue" : "white";
                }
            })
            .attr("id", function (d) {
                return d.id
            })
            .on("click", click);


        var node_text = nodeEnter.append("text")
            .style("font-size", function (d) {
                return d.children || d._children ? '8px' : '10px';
            })
            .style("cursor", "pointer")
            .attr("x", function (d) {
                return d.children || d._children ? -6 : 8;
            })
            .attr("dy", function (d) {
                return d.children || d._children ? -6 : 3;
            })
            .attr("text-anchor", function (d) {
                return d.children || d._children ? "end" : "start";
            })
            .text(function (d,i) {
                if (d.children || d._children) {
                    return d.annotation;
                } else if (d[label]) {
                    return d[label];
                } else {
                    return d.name;
                }
                //return i
            })
            .attr('fill', function (d) {
                return d.children || d._children ? "#ccc" : "black";
            })
            .on("click", function (d) {
                popup(d);
            });


        // Transition nodes to their new position.
        var nodeUpdate = node.transition()
            .duration(duration)
            .attr("transform", function (d) {
                return "translate(" + d.y + "," + d.x + ")";
            })
            .attr("distance", function (d) {
                if (d.species) {

                } else if (d.children) {
                    return findDistance(d)
                }
            });

        nodeUpdate.select("circle")
            .attr("r", 4.5)
            .attr("species", function (d) {
                return d.species
            })
            .attr("id", function (d) {
                return d.id
            })
            .style("fill", function (d, i) {
                if (d.highlighted == true) {
                    return "red"
                } else if (d.colours) {
                    return d.colours;
                } else {
                    return d._children ? "lightsteelblue" : "white";
                }
            })


        nodeUpdate.select("text")
            .style("fill-opacity", 1)
            .text(function (d, i) {
                if (d.children || d._children) {
                    return d.annotation;
                } else if (d[label]) {
                    return d[label];
                } else {
                    return d.name;
                }
                //return i

            });

        // Transition exiting nodes to the parent's new position.
        var nodeExit = node.exit().transition()
            .duration(duration)
            .attr("transform", function (d) {
                return "translate(" + source.y + "," + source.x + ")";
            })
            .remove();

        nodeExit.select("circle")
            .attr("r", 1e-6)
            .remove();


        nodeExit.select("text")
            .style("fill-opacity", 1e-6)
            .remove();


        // Stash the old positions for transition.
        nodes.forEach(function (d) {
            d.x0 = d.x;
            d.y0 = d.y;
        });
    }

    // Toggle children on click.
    function click(d, i) {
        
        var reroot_btn= $('<span/>', {
            text: "Re-root", //set text 1 to 10
            id: 'btn_'+i,
            class: 'popup_text',
            click: function () { reroot(d); }
        });

        $('#reroot').html(reroot_btn)

        var pathroparent_btn= $('<span/>', {
            text: "Path to parent", //set text 1 to 10
            id: 'btn_'+i,
            class: 'popup_text',
            click: function () { pathtoparent(d, i); }
        });        

        $('#pathroparent').html(pathroparent_btn)

        var openclose_btn= $('<span/>', {
            text: "Open - Close", //set text 1 to 10
            id: 'btn_'+i,
            class: 'popup_text',
            click: function () { openclose(d); }
        });

        $('#openclose').html(openclose_btn)



        if (mouseX + $("#popup2").width() > $("#main1").width()) {
            $("#popup2").css({"left": mouseX});// - $("#popup").width() - 5});
            $("#popup2").css({"top": (mouseY)});// - $("#popup").height() - 30)});
            $("#popup2").attr('class', 'bubbleright')
        }
        else {
            $("#popup2").css({"left": (mouseX)});// - 26)});
            $("#popup2").css({"top": (mouseY)});// - $("#popup").height() - 30)});
            $("#popup2").attr('class', 'bubbleleft')
        }

        $("#popup2").fadeIn();


    }

    function openclose(d){
        if (d.children) {
            d._children = d.children;
            d.children = null;
            update(d);
        } else if (d._children) {
            d.children = d._children;
            d._children = null;
            update(d);
        } 

        removePopup();
    }

    // Shows popup with links to NCBI
    function popup(d) {

        var header = "&nbsp;"

        if(d[parent.headers[0]]){
            header = d[parent.headers[0]]
        }
        $('#desc').html(header)


        var ncbiSeqURL = null;


        if (d.RepresentativeSequence && d.RepresentativeSequence.length > 0) {
            ncbiSeqURL = "https://www.ncbi.nlm.nih.gov/nuccore/" + d.RepresentativeSequence;
        }
        
        var ncbiSeqLink= $('<span/>', {
            text: "GenomeSeq", //set text 1 to 10
            class: 'popup_text',
            click: function () {   
                if (d.RepresentativeSequence && d.RepresentativeSequence.length > 0) {
                    window.open(ncbiSeqURL); 
                }
            }
        });        

        $('#ncbiSeqLink').html(ncbiSeqLink)

        var ncbiClusterURL = "https://www.ncbi.nlm.nih.gov/protein/" + d.ClusterSequences;

        var ncbiClusterLink= $('<span/>', {
            text: "ClusterSeqs", //set text 1 to 10
            class: 'popup_text',
            click: function () { window.open(ncbiClusterURL); }
        });        

        $('#ncbiClusterLink').html(ncbiClusterLink)



        if (mouseX + $("#popup").width() > $("#main1").width()) {
            $("#popup").css({"left": mouseX});
            $("#popup").css({"top": (mouseY)});
            $("#popup").attr('class', 'bubbleright')
        }
        else {
            $("#popup").css({"left": (mouseX)});
            $("#popup").css({"top": (mouseY)});
            $("#popup").attr('class', 'bubbleleft')
        }

        $("#popup").fadeIn();

    }


    // Re-root tree
    function reroot(node) {
        console.log("herere")
        if (node.parent) {

            var new_json = {
                'name': 'new_root',
                '__mapped_bl': undefined,
                'children': [node]
            }

            var nodes = tree.nodes(root)
            nodes.forEach(function (n) {
                n.__depth = n.depth;
            });

            var remove_me = node,
                current_node = node.parent,
                parent_length = current_node.depth;

            if (current_node.parent) {
                node.depth = node.depth === undefined ? undefined : node.depth * 0.5;
                stashed_bl = current_node.depth;
                current_node.__depth = node.__depth;
                new_json.children.push(current_node);
                while (current_node.parent) {
                    var remove_idx = current_node.children.indexOf(remove_me);
                    if (current_node.parent.parent) {
                        current_node.children.splice(remove_idx, 1, current_node.parent);
                    } else {
                        current_node.children.splice(remove_idx, 1);
                    }

                    var t = current_node.parent.__mapped_bl;
                    if (t !== undefined) {
                        current_node.parent.__depth = stashed_bl;
                        stashed_bl = t;
                    }
                    remove_me = current_node;
                    current_node = current_node.parent;
                }
                var remove_idx = current_node.children.indexOf(remove_me);
                current_node.children.splice(remove_idx, 1);
            } else {
                var remove_idx = current_node.children.indexOf(remove_me);
                current_node.children.splice(remove_idx, 1);
                remove_me = new_json;

            }

            if (current_node.children.length == 1) {
                remove_me.children = remove_me.children.concat(current_node.children);
            } else {
                var new_node = {
                    "name": "__reroot_top_clade"
                };
                new_node.__depth = stashed_bl;
                new_node.children = current_node.children.map(function (n) {
                    return n;
                });
                remove_me.children.push(new_node);

            }

        }

        root = new_json

        update(node);

        removePopup();


    }


    //highlight based on click
    function pathtoparent(d, i) {
        if (highlighted_parent != d) {

            // Walk parent chain
            var ancestors = [];
            var n_ancestors = [];
            var parent = d;
            highlighted_parent = parent;
            while (!_.isUndefined(parent)) {
                ancestors.push(parent);
                n_ancestors.unshift(parent.name);
                parent = parent.parent;
            }
            var breadcrumb = '';
            _.each(n_ancestors, function (key, val) {
                if (val < n_ancestors.length - 1) breadcrumb += key + ' / ';
                else breadcrumb += key;
            });
            $("#infobox").text(breadcrumb);

            var matchedLinks = [];
            svg.selectAll('path')
                .filter(function (d, i) {
                    return _.any(ancestors, function (p) {
                        return p === d.target;
                    });
                })
                .each(function (d) {
                    matchedLinks.push(d);
                });

            animateParentChain(matchedLinks);
        } else {
            d3.selectAll("path")
                .filter(function (d, i) {
                    d.highlighted = false;
                    d.source.highlighted = false;
                    if (!d.source.filtered || d.source.filtered == false) {
                        return d;
                    }
                })
                .style("fill", "none")
                .style("stroke", "#ccc");


            d3.selectAll("path")
                .style("fill", "none")
                .style("stroke-width", "1.5px");

            highlighted_parent = null;

        }

        removePopup();
    }

    function animateParentChain(links) {
        d3.selectAll("path")
            .filter(function (d, i) {
                if (!d.source.filtered || d.source.filtered == false) {
                    return d;
                }
            })
            .style("fill", "none")
            .style("stroke", "#ccc")


        d3.selectAll("path")
            .filter(function (d, i) {
                return _.any(links, function (p) {
                    if (d.target.id == p.target.id) {
                        d.target.highlighted = true;
                        d.highlighted = true

                        return d;
                    }
                });
            })
            .attr("class", "selected")
            .style("fill", "none")
            .style("stroke", "red")
            .style("stroke-width", "5px")
    }


    function change_distance(increase) {
        if (increase == true) {
            space += 10;
            height += 50
        } else {
            space -= 10;
            space = space < 1 ? 1 : space;
            height -= 50

        }
        tree.size([height, width]);
        tree.separation(function (a, b) {
            return ((a.parent == root) && (b.parent == root)) ? space : 1;
        })



        d3.select("svg")
            .attr("height", height  + margin.top + margin.bottom)

        update(root);
    }

    function findDistance(node) {
        var distance = 0;
        var list = []
        for (var i = 0; i < node.children.length; i++) {
            if (node.children[i].species) {
                list.push(node.children[i].species)
            } else if (node.children[i].children != null) {
                recursiveFinder(node.children[i])
            }
        }

        function recursiveFinder(child_node) {
            for (var j = 0; j < child_node.children.length; j++) {
                if (child_node.children[j].species) {
                    list.push(child_node.children[j].species)
                } else if (child_node.children[j].children != null) {
                    recursiveFinder(child_node.children[j])
                }
            }
        }

        for (var i = 0; i < list.length; i++) {
            for (var j = i; j < list.length; j++) {
                var array_element = findElement(parent.species, "species", list[i])
                var temp_distance = array_element ? array_element[list[j]] * 100 : 0

                if (distance < temp_distance) {
                    distance = temp_distance
                }
            }
            return distance.toFixed(2);
        }
    }

    function findElement(arr, propName, propValue) {
        for (var i = 0; i < arr.length; i++) {
            if (arr[i][propName] == propValue) {
                return arr[i];
            }
        }
    }

    //highlight based on filter

    function pathtohighlight(identity) {


        d3.selectAll("circle")
            .filter(function (d) {
                if (!d.highlighted) {
                    d.filtered = false;
                    d.colours = null;
                    return d;
                }
            })
            .transition()
            .style("fill", "none")

        d3.selectAll("circle")
            .filter(function (d) {
                if (d.highlighted) {
                    d.filtered = false;
                    d.colours = null;
                    return d;
                }
            })
            .transition()
            .style("fill", "red")

        d3.selectAll("path")
            .filter(function (d) {
                if (!d.target.highlighted) {
                    d.filtered = false;
                    d.colours = null;
                    return d
                }
            })
            .transition()
            .style("stroke", "#ccc")
            .style("stroke-width", "1.5px")

        d3.selectAll("path")
            .filter(function (d) {
                if (d.target.highlighted) {
                    d.filtered = false;
                    d.colours = null;
                    return d
                }
            })
            .transition()
            .style("stroke", "red")
            .style("stroke-width", "5px")


        var colour = 0
        var selected_nodes = {};

        d3.selectAll("circle")
            .filter(function (d, i) {
                if (d.distance <= identity || d.filtered == true) {
                    d.filtered = true
                    var flag = false;
                    if (d.colours == null) {
                        colour++;
                        d.colours = colours[colour]
                        var id = d.id
                        selected_nodes[id] = colours[colour]
                    }
                    if (d.children) {
                        _.any(d.children, function (p) {
                            p.filtered = true
                            if (p.colours == null) {
                                p.colours = colours[colour]
                                var id = p.id
                                selected_nodes[id] = colours[colour]

                            }
                        });
                    }

                } else if (d.distance > identity && d.filtered != true) {
                    d.filtered = false;
                    d.colours = null;
                    if (d.children) {
                        _.any(d.children, function (p) {
                            if (p.species) {
                                p.filtered = false
                                p.colours = null
                            }
                        });
                    }
                }
            });

        d3.selectAll("circle")
            .filter(function (d) {
                if (d.filtered == true) {
                    return d
                }
            })
            .transition()
            .style("fill", function (d, i) {
                return d.colours
            })


        svg.selectAll('path')
            .filter(function (d, i) {
                return _.any(selected_nodes, function (value, key) {
                    if (d.source.id == key) {
                        d.filtered = true
                        d.colours = value
                    }
                });

            })

        svg.selectAll('path')
            .filter(function (d) {
                if (d.filtered == true) {
                    return d
                }
            })
            .transition()
            .style("stroke", function (d, i) {
                console.log(d.colours)
                return d.colours
            })
    }

    function addLabels(root) {
        for (i in root) {
            if (root[i].name != "") {
                for (key in parent.labels[root[i].name]) {
                    root[i][key] = parent.labels[root[i].name][key]
                }
            }
        }
        return root
    }
}
