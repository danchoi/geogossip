var map = L.map('map', { dragging: false,
                         zoomControl: false,
                         zoomAnimation: false,
                         scrollWheelZoom: false,
                         doubleClickZoom: false,
                         touchZoom: false
                       }).setView([42.375, -71.106], 13);


L.tileLayer('http://{s}.tile.cloudmade.com/' + API_KEY + '/997/256/{z}/{x}/{y}.png', {
    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://cloudmade.com">CloudMade</a>',
    maxZoom: 18
}).addTo(map);


map.doubleClickZoom.disable();

var svg = d3.select(map.getPanes().overlayPane).append("svg").attr('class', 'myMapOverlay'),
    g = svg.append("g").attr("class", "leaflet-zoom");

function project(x) {
  var point = map.latLngToLayerPoint(new L.LatLng(x[0], x[1]));
  return [point.x, point.y];
}

function channelsWithLocations(x){
  return (!!x.latLng);
}

function ChatUICtrl ($scope, $http) {

  $scope.thisUser = {};

  $scope.refreshUsers = function() {
    $http.get("/users").success(function(data) {
      $scope.users = data;
    });
  }

  $scope.refreshUsers();

  $scope.loginUser = function(){
   if (has_local_storage()){
      if(localStorage['geogossip.user_id'] && localStorage['geogossip.user_nick']){
        $scope.thisUser.user_nick = localStorage['geogossip.user_nick']
        $scope.thisUser.user_id = localStorage['geogossip.user_id'];
        $scope.thisUser.already_created = true;
      }
    } 
  }
  $scope.loginUser();

  $scope.createUser = function() {
    console.log("SUCCESS!");
    $http.post("/users", $scope.thisUser).success(function(data) {
      $scope.thisUser.user_nick = data.user_nick;
      $scope.thisUser.user_id = data.user_id;
      if (has_local_storage()){
        localStorage['geogossip.user_nick'] = $scope.thisUser.user_nick; 
        localStorage['geogossip.user_id'] = $scope.thisUser.user_id;
        $scope.thisUser.already_created = true;
      } 
      $scope.thisUser.submitted = true;
      console.log("this user submitted is" + $scope.thisUser.submitted);      
    });
  }

  $scope.channels = [
    // {
    //   topic: "Best icecream @ JP Licks",
    //   messages: [
    //     {
    //       name: "Dan",
    //       message: "hey everyone"
    //     },
    //     {
    //       name: "Jon",
    //       message: "I like icecream and waffles!"
    //     }
    //   ],
    //   latLng: null
    // }
  ];

  $scope.selectChannel = function(idx){
    if(!$scope.thisUser.user_id){
      alert("Please enter a nickname");
      return;
    }
    $scope.activeChannel = $scope.channels[idx];
    $http.post('/memberships', {user_id: $scope.thisUser.user_id, channel_id: $scope.activeChannel.channel_id})
      .success(function(data){
        console.log(data);
      });
    console.log("active channel is: " + $scope.activeChannel.topic);
  };

  $scope.addMessage = function(msg){
    console.log("running addMessage");
    $scope.activeChannel.messages.push({
      name: "Anon",
      message: $scope.newMessage
    });

    $scope.newMessage = "";
  };

  $scope.createTopic = function () {
    console.log("running createTopic");
    $http.post("/channels", {new_topic_name: $scope.newTopicName}).success(function(data) {
      console.log('got back this topic');
      console.log(data);
      $scope.activeChannel = data;
      $scope.loadChannels();
    });

    $scope.newTopicName = "";
  };

  $scope.loadChannels = function (){
    $http.get("/channels").success(function(data) {
      $scope.channels = data;
    });
  };
  $scope.loadChannels();

  function has_local_storage(){
    try {
      return 'localStorage' in window && window['localStorage'] !== null;
    } catch (e) {
      return false;
    };
  };

  $scope.populateMap = function (){
    var xs = $.grep($scope.channels, channelsWithLocations);
    console.log("running drawMap");
    console.log(xs);
    svg.selectAll('circle').remove();
    svg.selectAll("circle")
    .data(xs)
    .enter().append("circle")
    .attr('class', 'geoChatCircle')
    .attr("cx", function(d) {
      console.log(d.latLng);
      console.log(project(d.latLng));
      return (project(d.latLng)[0]);
    })
    .attr("cy", function(d) {return (project(d.latLng)[1])})
    .attr("r", 12)
    .style("fill", "#f03")
    .style('fill-opacity', 0.3)
    .style("stroke", "red")
    .style("stroke-opacity", 1)
    .style("stroke-width", 3);
  };

  $scope.populateMap();

  map.on('click', function (e) {
    var latLng = [e.latlng.lat, e.latlng.lng];
    console.log(latLng);
    var newChannel = {
      topic: "some topic",
      messages: [],
      latLng: latLng
    };
    $scope.channels.push(newChannel);
    console.log($scope.channels);

    $scope.$apply();
    $scope.populateMap();

  });

}
