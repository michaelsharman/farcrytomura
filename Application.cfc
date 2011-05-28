<cfcomponent output="false">


	<cfscript>

		this.name = "farcrytomura";
		this.applicationTimeout = createTimeSpan(0,2,0,0);
		this.sessionManagement = true;
		this.sessionTimeout = createTimeSpan(0,0,20,0);
		this.setClientCookies = true;
		this.scriptProtect = "all";
	
	</cfscript>

	
	<cffunction name="onApplicationStart" returnType="boolean" output="false">
		
		<cfreturn true>
	</cffunction>
	
	
	<cffunction name="onError" returnType="void" output="false">
		<cfargument name="exception" required="true">
		<cfargument name="eventname" type="string" required="true">

		<!--- Fixes cflocation bug which calls onError() in CF8.0 --->
		<cfif structKeyExists(arguments.exception, "type") AND arguments.exception.type EQ "coldfusion.runtime.AbortException">
			<cfreturn>
		</cfif>
		
		<cfdump var="#arguments#">
		<cfabort>
	</cffunction>

	
	<cffunction name="onRequestStart" returnType="boolean" output="false">
		<cfargument name="thePage" type="string" required="true">
		
		<cfreturn true>
	</cffunction>

	
</cfcomponent>