<cfsetting enablecfoutputonly="true">
<!---
	Name			: header.cfm
	Author			: Michael Sharman (michael[at]chapter31[dot]com)
	Created			: May 26, 2011
	Last Updated		: May 26, 2011
	History			: Initial release (mps 26/05/2011)
	Purpose			: HTML header template, use if you want to change navigation
 --->

<cfparam name="URL.step" default="DSN">

<cfoutput><!DOCTYPE html>
<html dir="ltr" lang="en">
	<head>
  		<meta charset="utf-8">
		<title>farcrytomura</title>
		<link rel="stylesheet" href="static/main.css" />
		<link rel="stylesheet" href="static/forms.css" />
	</head>
	<body>
		<h1>FarCry to Mura</h1>
		<p>Make your way through the menu below, from left to right. See the <a href="index.cfm?step=help">help page</a> if you get stuck.</p>
		<h3>Progress &raquo;</h3>
		<ul id="nav">
			<li><cfif trim(URL.step) EQ "DSN">Set DSNs<cfelse><a href="index.cfm">Set DSNs</a></cfif></li>
			<li><cfif trim(URL.step) EQ "muraSiteID">Set Mura SiteID<cfelse><a href="index.cfm?step=muraSiteID">Set Mura SiteID</a></cfif></li>
			<li><cfif trim(URL.step) EQ "checkFarCry">Check FarCry<cfelse><a href="index.cfm?step=checkFarCry">Check FarCry</a></cfif></li>
			<li><cfif trim(URL.step) EQ "checkMura">Check Mura<cfelse><a href="index.cfm?step=checkMura">Check Mura</a></cfif></li>
			<li><cfif listFind("preImport,doMigration", trim(URL.step))>Do Migration<cfelse><a href="index.cfm?step=preImport">Do Migration</a></cfif></li>
			<li><cfif trim(URL.step) EQ "help">Help<cfelse><a href="index.cfm?step=help">Help</a></cfif></li>
		</ul>
</cfoutput>

<cfsetting enablecfoutputonly="false">