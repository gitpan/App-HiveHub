
var socket;

var graph;
var legend;
var xAxis;

var palette = new Rickshaw.Color.Palette();
var graph_duration = { 'minutes': 5 };

var sources = [];
var seriesData = [];
var objects = [];

$(function(){

  socket = io.connect();

  socket.on('connect',function(){
    $('#status').text('Connected, waiting for sources...');
  });

  socket.on('disconnect',function(){
    $('#status').text('Disconnected, waiting for reconnect...');
  });

  socket.on('data', function(received_data){
    console.log(received_data);
    if (received_data.data) {
      objects.push(received_data);
    }
    if (!sources.length) {
      if (received_data.sources) {
        $('#status').text('Got sources...');
        $(received_data.sources).each(function(idx,source){
          sources.push({
            name: source,
            color: palette.color(),
          });
        });
      }
    }
    if (sources.length) {
      var till = moment().subtract(graph_duration);
      $(objects).each(function(obj_idx,object) {
        if (object && object.timestamp) {
          var timestamp = object.timestamp;
          if (moment.unix(timestamp).isAfter(till)) {
            $(object.data).each(function(idx,data){
              var device = data[0]-1;
              if (!seriesData[device]) {
                seriesData[device] = [];
              }
              var value = data[1];
              seriesData[device].push({ x: timestamp, y: value });
            });
          }
        }
        delete objects[obj_idx];
      });
      $(seriesData).each(function(idx){
        var old = [];
        $(seriesData[idx]).each(function(data_idx,serieData){
          if (moment.unix(serieData.x).isBefore(till)) {
            old.push(data_idx);
          }
        });
        $(old.reverse()).each(function(data_idx){
          delete seriesData[idx][data_idx];
        });
      });
      console.log(seriesData);
      if (!graph) {
        var series = [];
        $(sources).each(function(idx,source){
          var new_source = jQuery.extend({ data: seriesData[idx] }, source);
          series.push(new_source);
        });
        graph = new Rickshaw.Graph({
          element: document.querySelector("#chart"),
          height: 400,
          min: 0,
          renderer: 'line',
          series: series
        });
        legend = new Rickshaw.Graph.Legend({
          graph: graph,
          element: document.querySelector('#legend')
        });
        xAxis = new Rickshaw.Graph.Axis.X( {
          graph: graph,
          tickFormat: function(n){
            return moment.unix(n).format("HH:mm:ss");
          }
        });
        // xAxis = new Rickshaw.Graph.Axis.Time({
        //   graph: graph
        // });
        graph.render();
      } else {
        graph.update();
      }
    }
  });

});
