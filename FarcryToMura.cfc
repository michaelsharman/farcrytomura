<cfcomponent displayname="FarcryToMura" output="false" hint="Imports basic content/navigation from FarCry to Mura">
<!---
	Name			: FarcryToMura.cfc
	Author			: Michael Sharman (michael[at]chapter31[dot]com)
	Created			: May 26, 2011
	Last Updated		: May 26, 2011
	History			: Initial release (mps 26/05/2011)
	Purpose			: Imports basic dmHTML data from FarCry into Mura
	Requirements		: Was built on 
							Railo 3.2+
							FarCry 6+
							Mura 5.4+
							MySQL 5+
						In reality this *should* work on CF7+
						Not sure about FarCry 5, you should be ok as I don't think the v6 schema changes will effect this script
						To make things easier, session management should enabled
	Installation		: Probably easiest to put this folder (farcrytomura) in the webroot of an existing project,
						then call it from http://www.yourproject.com/farcrytomura/
						If you want, you can setup a vhost specifically for this, but it's not necessary.
						Caveat - the instance/context that you run this from needs to have BOTH dsn's (the FarCry and Mura ones) in the cf admin
 --->

	
	<cffunction name="init" access="public" output="false" returnType="FarcryToMura">
		
		<cfscript>
			variables.instance = structNew();
			variables.instance.muraSiteID = "";
			variables.instance.fromDSN = "";
			variables.instance.toDSN = "";
			
			return this;
		</cfscript>
	</cffunction>
	
	
	<cffunction name="checkDSNs" access="public" output="false" returnType="struct" hint="Checks that both DSN's can connect to their db's">
		
		<cfset var q = "">
		<cfset var result = structNew()>
		
		<cfset result.status = true>
		<cfset result.errors = arrayNew(1)>
		
		<!--- Check the farcry ('from') DSN --->
		<cftry>
			<cfquery name="q" datasource="#getFromDSN()#">
				SELECT 1 FROM dmHTML
			</cfquery>

			<cfcatch type="database">
				<cfset result.status = false>
				<cfset arrayAppend(result.errors, "Your 'From DSN' ('FarCry') was not found - you entered '#getFromDSN()#'")>
			</cfcatch>
		</cftry>
		
		<!--- Check the mura ('to') DSN --->
		<cftry>
			<cfquery name="q" datasource="#getToDSN()#">
				SELECT 1 FROM tcontent
			</cfquery>

			<cfcatch type="database">
				<cfset result.status = false>
				<cfset arrayAppend(result.errors, "Your 'To DSN' ('Mura') was not found - you entered '#getToDSN()#'")>
			</cfcatch>
		</cftry>
		
		<cfif NOT result.status>
			<cfset result.message = "DSN error">
		</cfif>
		
		<cfreturn result>
	</cffunction>
	
	
	<cffunction name="doImport" access="public" output="false" returnType="struct">
	
		<cfscript>
			var q = "";
			var result = structNew();
			var qFC = getFarcryTree();
			var qM = getMuraTree();
			var dbDateNow = createODBCDateTime(now());
			var dbModule = '00000000000000000000000000000000000';
			var dbMuraParentID = qM['ContentID'][1];		// Default parentID of the first node in Mura
			var dbParentID = "";
			var dbContentID = "";
			var dbPreviousContentID = "";
			var dbOrderNo = 1;
			var dbPath = dbMuraParentID;
			var dbFilename = "";
			var dbURLTitle = "";
			var currentLevel = 0;
			var previousLevel = 0;
			var sortOrder = structNew();
			
			result.status = true;
			result.errors = arrayNew(1);
		</cfscript>
		
		<cftry>

			<cfloop query="qFC">
				<cfset currentLevel = qFC.nLevel>
				
				<cfset dbContentID = qFC.navObjectId>
				<cfif qFC.nLevel EQ 2>
					<!--- For all 'home' nodes, use the first mura contentId --->
					<cfset dbParentID = dbMuraParentID>
				<cfelse>
					<cfset dbParentID = qFC.navParentId>
				</cfif>
				
				<!--- Setup the sortorder. Note: sub-nodes aren't starting at 1 (after the first one). Not neat, but will work fine --->
				<cfif NOT structKeyExists(sortOrder, qFC.nLevel)>
					<cfset sortOrder[qFC.nLevel] = 0>
				</cfif>
				<cfset sortOrder[qFC.nLevel] = sortOrder[qFC.nLevel] + 1>
				<cfset dbOrderNo = sortOrder[qFC.nLevel]>
				
				<!--- Set SES values --->
				<cfset dbURLTitle = qFC.title>
				<cfset dbURLTitle = reReplace(lCase(dbURLTitle), "[^a-zA-Z0-9 -]", "", "all")>
				<cfset dbURLTitle = replace(dbURLTitle, " ", "-", "all")>

				<!--- Set path and filename --->
				<cfif currentLevel GT previousLevel>
					<cfset dbPath = listAppend(dbPath, dbContentId)>
					<cfset dbFilename = listAppend(dbFilename, dbURLTitle, "/")>
				<cfelseif currentLevel EQ previousLevel>
					<cfset dbPath = listSetAt(dbPath, listLen(dbPath), dbContentId)>
					<cfset dbFilename = listSetAt(dbFilename, listLen(dbFilename, "/"), dbURLTitle, "/")>
				<cfelseif currentLevel LT previousLevel>
					<cfloop from="1" to="#previousLevel - currentLevel#" index="i">
						<cfset dbPath = listDeleteAt(dbPath, listLen(dbPath))>
						<cfset dbFilename = listDeleteAt(dbFilename, listLen(dbFilename, "/"), "/")>
					</cfloop>
					<cfset dbPath = listSetAt(dbPath, listLen(dbPath), dbContentId)>
					<cfset dbFilename = listSetAt(dbFilename, listLen(dbFilename, "/"), dbURLTitle, "/")>
				</cfif>

				<cfset previousLevel = currentLevel>

				<cfquery name="q" datasource="#getToDSN()#">
					INSERT INTO tcontent
					(
						SiteID,
						ModuleID,
						ParentID,
						ContentID,
						ContentHistID,
						RemoteID,
						TYPE,
						subType,
						Active,
						OrderNo,
						Title,
						MenuTitle,
						Summary,
						Filename,
						MetaDesc,
						MetaKeyWords,
						Body,
						lastUpdate,
						Display,
						Approved,
						IsNav,
						Restricted,
						Target,
						responseChart,
						displayTitle,
						inheritObjects,
						isFeature,
						IsLocked,
						nextN,
						sortBy,
						sortDirection,
						forceSSL,
						searchExclude,
						PATH,
						doCache,
						urltitle,
						htmltitle,
						created,
						mobileExclude
					) 
					VALUES
					(
						'#getMuraSiteID()#',			<!--- SiteID --->
						'#dbModule#',				<!--- ModuleID --->
						'#dbParentID#',				<!--- ParentID --->
						'#dbContentID#',			<!--- ContentID --->
						'#createUUID()#',			<!--- ContentHistID --->
						'farcrytomura',				<!--- RemoteID (Obviously not a real Mura user, but good as an indication of where the record(s) came from) --->
						'Page',					<!--- TYPE --->
						'Default',					<!--- subType --->
						1,						<!--- Active --->
						#dbOrderNo#,				<!--- OrderNo --->
						'#qFC.pageTitle#',			<!--- Title --->
						'#qFC.title#',				<!--- MenuTitle --->
						'#qFC.teaser#',				<!--- Summary --->
						'#dbFilename#',			<!--- Filename --->
						'',						<!--- MetaDesc --->
						'#qFC.metaKeywords#',		<!--- MetaKeyWords --->
						'#qFC.body#',				<!--- Body --->
						#dbDateNow#,				<!--- lastUpdate --->
						1,						<!--- Display --->
						1,						<!--- Approved --->
						1,						<!--- IsNav --->
						0,						<!--- Restricted --->
						'_self',					<!--- Target --->
						0,						<!--- responseChart --->
						0,						<!--- displayTitle --->
						'Inherit',					<!--- inheritObjects --->
						0,						<!--- isFeature --->
						0,						<!--- IsLocked --->
						10,						<!--- nextN --->
						'orderno',					<!--- sortBy --->
						'asc',						<!--- sortDirection --->
						0,						<!--- forceSSL --->
						0,						<!--- searchExclude --->
						'#dbPath#',				<!--- PATH --->
						1,						<!--- doCache --->
						'#dbURLTitle#',				<!--- urltitle --->
						'#qFC.pageTitle#',			<!--- htmltitle --->
						#dbDateNow#,				<!--- created --->
						0						<!--- mobileExlude --->
					);
				</cfquery>
			</cfloop>

			<cfcatch type="any">
				<cfdump var="#cfcatch#">
				<cfabort>
			</cfcatch>
		</cftry>
			
		<cfreturn result>
	</cffunction>
	
	
	<cffunction name="dump" access="public" output="false" returnType="struct">
	
		<cfreturn variables.instance>
	</cffunction>
	
	
	<cffunction name="getFarcryTree" access="public" output="false" returnType="query">
	
		<cfset var q = "">
	
		<cfquery name="q" datasource="#getFromDSN()#">
			SELECT n.title, ref.typename, nto.objectId as navObjectId, nto.parentId as navParentId, nto.NLEFT, nto.NRIGHT, nto.NLEVEL, h.title as pageTitle, h.body, h.teaser, h.metaKeywords
			FROM dmNavigation n
			INNER JOIN nested_tree_objects nto
			ON n.ObjectID = nto.objectid
			INNER JOIN dmNavigation_aObjectIDs no
			ON n.ObjectID = no.parentid
			INNER JOIN refObjects ref
			ON no.data = ref.objectid
			LEFT OUTER JOIN dmHTML h
			ON h.ObjectID = no.data
			WHERE n.status = 'approved'
			AND nLevel > 1	<!--- Ignoring home and any other level 1 pages (secondary nav etc) ---><!--- TODO: Fix it so we can grab the homepage and/or secondary nav nodes --->
			ORDER BY nto.NLEFT
		</cfquery>
	
		<cfreturn q>
	</cffunction>


	<cffunction name="getFromDSN" access="public" output="false" returnType="string">
	
		<cfreturn variables.instance.fromDSN>
	</cffunction>
	
	
	<cffunction name="getToDSN" access="public" output="false" returnType="string">
	
		<cfreturn variables.instance.toDSN>
	</cffunction>


	<cffunction name="getAvailableMuraSiteIDs" access="public" output="false" returnType="query">
	
		<cfset var q = "">
	
		<cfquery name="q" datasource="#getToDSN()#">
			SELECT distinct siteID
			FROM tcontent
			ORDER BY siteID
		</cfquery>
	
		<cfreturn q>
	</cffunction>


	<cffunction name="getMuraSiteId" access="public" output="false" returnType="string">
	
		<cfreturn variables.instance.muraSiteID>
	</cffunction>


	<cffunction name="getMuraTree" access="public" output="false" returnType="query">
	
		<cfset var q = "">
	
		<cfquery name="q" datasource="#getToDSN()#">
			SELECT title, menuTitle, filename, htmlTitle, urlTitle, body, contentId, parentId
			FROM tcontent
			WHERE SiteID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#getMuraSiteID()#">
			AND type = 'Page'
			AND isNav = 1
			AND approved = 1
			AND active = 1
		</cfquery>
	
		<cfreturn q>
	</cffunction>


	<cffunction name="hasDSNs" access="public" output="false" returnType="boolean">
		
		<cfreturn len(trim(getFromDSN())) AND len(trim(getToDSN()))>
	</cffunction>
	
	
	<cffunction name="hasMuraSiteID" access="public" output="false" returnType="boolean">
	
		<cfreturn len(trim(variables.instance.muraSiteID))>
	</cffunction>


	<cffunction name="locate" access="public" output="false" returnType="string" hint="Does cflocation purely because of crappy support for script based options pre-cf8 (or 9)">
		<cfargument name="step" type="string" required="true" hint="Step to redirect to">
	
		<cflocation addtoken="false" url="index.cfm?step=#arguments.step#">
	</cffunction>


	<cffunction name="setDSNs" access="public" output="false" returnType="struct">
		<cfargument name="fromDSN" type="string" required="true" hint="FarCry DSN">
		<cfargument name="toDSN" type="string" required="true" hint="Mura DSN">

		<cfscript>
			var result = structNew();

			result.errors = arrayNew(1);
			result.status = true;
			
			if (NOT len(trim(arguments.fromDSN)) OR NOT len(trim(arguments.toDSN)))
			{
				result.status = false;
				result.message = "Error setting DSNs";
				arrayAppend(result.errors, "Please enter both DSNs");
			}

			// Set the class vars anyway, in case one of the values was passed in etc
			variables.instance.fromDSN = arguments.fromDSN;
			variables.instance.toDSN = arguments.toDSN;
			
			return result;
		</cfscript>	
	</cffunction>
	
	
	<cffunction name="setMuraSiteID" access="public" output="false" returnType="struct">
		<cfargument name="siteID" type="string" required="true" hint="Mura DSN">

		<cfscript>
			var result = structNew();

			result.errors = arrayNew(1);
			result.status = true;
			
			if (NOT len(trim(arguments.siteID)))
			{
				result.status = false;
				result.message = "Error setting Mura SiteID";
				arrayAppend(result.errors, "Please choose a siteID");
			}
			else
			{
				variables.instance.muraSiteID = arguments.siteID;
			}
			
			return result;
		</cfscript>
	</cffunction>


	<cffunction name="validateStep" access="public" output="false" returnType="struct">
		<cfargument name="step" type="string" required="true">
	
		<cfscript>
			var result = structNew();
			var checklist = "";
			var q = "";
			var r = "";

			result.errors = arrayNew(1);
			result.status = true;
			
			// Setup what we need to validate on for a specific step
			switch (arguments.step)
			{
				case "muraSiteID":
					checklist = listAppend(checklist, "DSN,checkDSNs");
					break;
				case "checkFarCry":
					checklist = listAppend(checklist, "DSN,checkDSNs,muraSiteID,checkFarCry");
					break;
				case "checkMura":
					checklist = listAppend(checklist, "DSN,checkDSNs,muraSiteID,checkFarCry,checkMura");
					break;
				case "preImport":
					checklist = listAppend(checklist, "DSN,checkDSNs,muraSiteID");
					break;
				default:
					break;
			}

			// Validate based on the checklist
			if (listFind(checklist, "DSN") AND NOT hasDSNs())
			{
				arrayAppend(result.errors, "Please choose your dsn's in step 1");
			}
			if (listFind(checklist, "checkDSNs") AND hasDSNs())
			{
				r =  checkDSNs();
				if (NOT r.status)
				{
					arrayAppend(result.errors, "Please check your DSN's, one or both have failed");
				}
			}
			if (listFind(checklist, "muraSiteID") AND NOT hasMuraSiteID())
			{
				arrayAppend(result.errors, "Please choose your mura siteID step 2");
			}
			if (listFind(checklist, "checkFarCry") AND NOT arrayLen(result.errors))
			{
				q = getFarcryTree();
				if (NOT q.recordCount)
				{
					arrayAppend(result.errors, "No records found for the <em>#getFromDSN()#</em> FarCry DSN.");
				}
			}
			if (listFind(checklist, "checkMura") AND NOT arrayLen(result.errors))
			{
				q = getMuraTree();
				if (NOT q.recordCount)
				{
					arrayAppend(result.errors, "No records found for the <em>#getToDSN()#</em> Mua DSN.");
				}
			}
			
			if (arrayLen(result.errors))
			{
				result.status = false;
				result.message = "Error";
			}
			
			return result;
		</cfscript>	
	</cffunction>
	
	
</cfcomponent>