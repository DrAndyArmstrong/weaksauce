--AA15 Weaksauce Resturant Reviewer
--Mock up

--systemID and expiration time for cookies

local systemID = "weaksauce"
local expireTime = os.time()+18000

--The database creation script (as an array)
createScript = {
	[[DROP TABLE IF EXISTS `resturant`;]],

	[[CREATE TABLE `resturant` (
	  `uid` int(11) NOT NULL AUTO_INCREMENT,
	  `name` text NOT NULL,
	  `cuisine` text NOT NULL,
	  `address` text NOT NULL,
	  `description` text NOT NULL,
	  `postcode` text NOT NULL,
	  `bottomRange` integer DEFAULT 0,
	  `topRange` integer DEFAULT 0,
	  `imageName` text NOT NULL,
	  PRIMARY KEY (`uid`)
	) ENGINE=InnoDB DEFAULT CHARSET=latin1;]],

	[[DROP TABLE IF EXISTS `reviews`;]],

	[[CREATE TABLE `reviews` (
	  `resturant_uid` int(11) NOT NULL,
	  `username` text NOT NULL,
	  `description` text,
	  `stars` int(11) DEFAULT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=latin1;]], 

	[[INSERT INTO resturant VALUES ("", "Prezzo", "Italian", "2 Castle Street, Oxford", "Chain Resturant", "OX1 1AY", 12, 15, "prezzo.jpg")]],

	[[INSERT INTO resturant VALUES ("", "Browns", "Brasserie", "90, The Market, High Street, Oxford", "Chain Resturant", "OX1 3DY", 20, 150, "browns.jpg")]],

	[[INSERT INTO reviews VALUES (1, "Freddy", "Was OK", 3)]],

	[[INSERT INTO reviews VALUES (2, "Norman", "Excellent Food, well recommended", 5)]],
}

local postCode = (cgilua.cookies.get(systemID) or "")
local rememberPostCode = ""
if postCode ~= "" then
	rememberPostCode = " checked"
end

local postCodeForm = [[
<form class="form-inline" role="form" method="post" action="index.lua?menu=search">
	<div class="form-group">
		<label for="postcode">Post Code:</label>
		<input type="postcode" class="form-control" name="postcode" value="]] .. postCode .. [[">
	</div>
	<div class="checkbox">
		<label><input type="checkbox" name="remember" ]] .. rememberPostCode .. [[> Remember postcode</label>
	</div>
	<button type="submit" class="btn btn-default">Submit</button>
</form>
]]

function amIActive(name, currentOption)
	if name == currentOption then
		return [[ class="active"]]
	end
	return ""
end

function insertContent(query, post) 
	local ot = "" 
	if query.menu == "about" then
		ot = [[<p class="lead">Welcome to Weaksauce, your online guide to the best resturants around!</p>]]
		ot = ot .. [[Functional prototype, Andrew Armstrong 13/04/2015]]
		ot = ot .. [[<br> Set as a challenge to see what I could knock up in a couple of hours!]]
	elseif query.menu == "contact" then
		ot = [[<p class="lead">Andrew Armstrong</p>]]
		ot = ot .. [[<p>Email: a.j.armstrong@gmail.com</p>]]
		ot = ot .. [[<p>Linkedin: <a href="https://uk.linkedin.com/in/andrewarmstong">https://uk.linkedin.com/in/andrewarmstong</a></p>]]
		ot = ot .. [[<p>angel list: <a href="https://angel.co/dr-andrew-armstrong">https://angel.co/dr-andrew-armstrong</a></p>]]
	elseif query.menu == "search" and post.postcode then
		ot = [[<p class="lead">Search Results for <b>]] .. post.postcode .. [[</b></p>]]
		if post.remember == "on" then
			cgilua.cookies.set(systemID, post.postcode ,{path="/", expires=expireTime, domain=""})
		else
			cgilua.cookies.set(systemID, "" ,{path="/", expires=expireTime, domain=""})
			cgilua.cookies.delete(systemID)
		end

		local restList, markers = getResturants(query, post)

		ot = ot .. insertMap(query, post, markers) .. [[<br>]]
		ot = ot .. restList
	else
		ot = [[<p class="lead">Enter your postcode to find your next favourite resturant (I suggest OX1 2JD!):</p>]] .. postCodeForm
	end
	return ot
end

function insertMap(query, post, markers)
	local ot = [[
		<script src="http://maps.googleapis.com/maps/api/js?sensor=false" type="text/javascript"></script>
                    <script>
                        var address = ']] .. post.postcode .. [[';
			var iconBase = 'https://maps.google.com/mapfiles/kml/shapes/';
                        var geocoder;
                        var map;
                        function initialize() {
                          geocoder = new google.maps.Geocoder();
                          var latlng = new google.maps.LatLng(-34.397, 150.644);
                          var mapOptions = {
                            zoom: 14,
                            center: latlng,
                            mapTypeId: google.maps.MapTypeId.ROADMAP
                          }
                          map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
			  codeAddress();
                        }

                        function codeAddress() {
                          geocoder.geocode( { 'address': address}, function(results, status) {
                            if (status == google.maps.GeocoderStatus.OK) {
                              map.setCenter(results[0].geometry.location);
                              var marker = new google.maps.Marker({
                                  map: map,
                                  position: results[0].geometry.location
                              });
                            } else {
                              alert('Geocode was not successful for the following reason: ' + status);
                            }
                          });

			  ]] .. markers .. [[

                        }

			function getAddress(postCode, ourTitle) {
				geocoder.geocode( { 'address': postCode }, function(results, status, ourTitle) 
					{
						if (status == google.maps.GeocoderStatus.OK) {
							var marker = new google.maps.Marker({
							map: map,
							position: results[0].geometry.location,
							title: ourTitle,
							icon: iconBase + 'dining.png'
						});
					}
				});
			}

                        google.maps.event.addDomListener(window, 'load', initialize);
 			</script>
                        <div id="map-canvas" style="width:100%;height:350px;"></div>
]]
	return ot
end

function getResturants(query, post)
	local ot = [[<p class="lead">Resturants near you:</p>]]
	local markers = [[]]

	local data = select('resturant', '*', nil, nil, nil, nil, true)

	for i,v in ipairs(data) do
		markers = markers .. [[getAddress(']] .. v.postcode..[[', "]] .. v.name .. [[");]]
		ot = ot .. 	[[<img src="images/resturantThumbs/]] .. v.imageName .. [[">]] .. 
				v.name .. ' ' .. 
				v.description .. ' ' ..
				'£' .. v.bottomRange .. '-£' .. v.topRange .. ' ' .. v.postcode

		local reviewData = select('reviews', '*', "resturant_uid = " .. v.uid, nil, nil, nil, true)

		for j,k in ipairs(reviewData) do
			local stars = ""
			for j = 1, (tonumber(k.stars) or 1) do
				stars = stars .. [[<img src="images/star.png">]]
			end	
			ot = ot .. [[ ']] .. k.description .. [[']] .. stars
		end

		ot = ot .. "<br>"
	end

	return ot, markers
end














