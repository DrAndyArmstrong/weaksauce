--AA15

local version = "1.0"

local cookies = require "cgilua.cookies"

--Using dofile rather than require, for this quick POC I do not want 
--to spend too much time creating modules

dofile "db.lua"
dofile "functions.lua"

local query = cgilua.QUERY or ""
local post = cgilua.POST or ""

if query.WIPE=="YES" then
	print ([[<b>Initialising...</b><br><br>]])

	for i,v in pairs(createScript) do
		print([[Executing SQL: - ]] .. v .. [[<br><br>]])
		executeSQL(v)
	end

	print ([[<b>I have initialised the system. I'm completely operational, and all my circuits are functioning perfectly</b>]])
	print ([[<br><br><b>Dave, you might consider passwording (or totally removing!) this function in the future!</b>]])

	return true
end

print([[

<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<!-- Andrew Armstrong 13/04/15 - First attempt at using bootstrap -->
	<!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
	<title>Weaksauce - your portal to good food</title>

	<!-- Bootstrap -->
	<link href="css/bootstrap.min.css" rel="stylesheet">

	<!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
	<!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
	<!--[if lt IE 9]>
	<script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
	<script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
	<![endif]-->
</head>
<body>

	<br><br><br>

	<nav class="navbar navbar-inverse navbar-fixed-top">
		<div class="container">
		<div class="navbar-header">
			<button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
				<span class="sr-only">Toggle navigation</span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
			</button>
			<img src='images/weaksauce.png'>
		</div>
		<div id="navbar" class="collapse navbar-collapse">
			<ul class="nav navbar-nav">
				<li]] .. amIActive("home", query.menu) .. [[><a href="index.lua?menu=home">Home</a></li>
				<li]] .. amIActive("about", query.menu) .. [[><a href="index.lua?menu=about">About</a></li>
				<li]] .. amIActive("contact", query.menu) .. [[><a href="index.lua?menu=contact">Contact</a></li>
			</ul>
		</div><!--/.nav-collapse -->
		</div>
	</nav>

    	<div class="container">

      	<div class="starter-template">

	<h1>Weaksauce ]] .. version .. [[</h1>

	]] .. insertContent(query, post) .. [[

      </div>

    </div><!-- /.container -->

	<!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
	<!-- Include all compiled plugins (below), or include individual files as needed -->
	<script src="js/bootstrap.min.js"></script>
</body>
</html>

]])
