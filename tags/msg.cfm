<cfsetting enablecfoutputonly="true" />
<!---
	Name			: _msg.cfm
	Author			: Michael Sharman (michael[at]chapter31[dot]com)
	Created			: January 11, 2008
	Last Updated		: January 11, 2008
	History			: Initial release (mps 11/01/2008)
	Purpose			: Displays an HTML list of messages
					: Expects a struct with at least 2 keys:
						- errors (Array[1]) Note: This can be used for generic messages as well.
						- message (String)
 --->


<cfif NOT structKeyExists(attributes, "data") OR NOT isValid("struct", attributes.data)>
	<cfoutput>Please pass a valid data struct</cfoutput>
	<cfabort>
</cfif>


<cfparam name="attributes.class" default="message-error">


<cfif (structKeyExists(attributes.data, "message") AND len(trim(attributes.data.message))) OR (structKeyExists(attributes.data, "errors") AND arrayLen(attributes.data.errors))>
	<cfoutput>
		<div class="#attributes.class#">
			<cfif structKeyExists(attributes.data, "message") AND len(trim(attributes.data.message))><h3>#attributes.data.message#</h3></cfif>
			<cfif structKeyExists(attributes.data, "errors") AND arrayLen(attributes.data.errors)>
				<ul>
					<cfloop from="1" to="#arrayLen(attributes.data.errors)#" index="i">
						<cfif len(trim(attributes.data.errors[i]))>
							<li>#attributes.data.errors[i]#</li>
						</cfif>
					</cfloop>
				</ul>
			</cfif>
		</div>
	</cfoutput>
</cfif>


<cfsetting enablecfoutputonly="false" />