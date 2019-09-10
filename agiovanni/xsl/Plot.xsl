<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="utf-8" omit-xml-declaration="yes"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>


  <xsl:template match="/">
    <xsl:apply-templates select="Services"/>
  </xsl:template>
<xsl:template name="Services" match = "/">

 <div  class="pickerContent" style="background-color:#ccddee">
   <p/>
		<legend>Set Time and Space Constraints and begin your Analysis using <xsl:value-of select="/root/@service"/></legend>
	<p/>
    <table align="center">
    <form action="../../giovanni/daac-bin/service_manager.pl">
            <xsl:element name="input">
                    <xsl:attribute name="name">data</xsl:attribute>
                    <xsl:attribute name="type">hidden</xsl:attribute>
                    <xsl:attribute name="value"><xsl:value-of select="/root/@variable1"/>
                     <xsl:text>,</xsl:text> 
                     <xsl:value-of select="/root/@variable2"/></xsl:attribute>
            </xsl:element>

            <xsl:if test="/root/@service != ''">
              <xsl:element name="input">
                    <xsl:attribute name="name">service</xsl:attribute>
                    <xsl:attribute name="type">hidden</xsl:attribute>
                    <xsl:attribute name="value"><xsl:value-of select="/root/@service"/></xsl:attribute>
              </xsl:element>
            </xsl:if>
     <input type="hidden" name="portal" value="GIOVANNI" />
     <table align="center" border="1" width="80%" style="background-color:#ccddee"><xsl:value select="/root/@plot_name"/>
      <tr>
        <td align="center" colspan="2">
            <h2><xsl:value-of select="/root/@plot_description"/><legend><xsl:value-of select="/root/@plot_subtitle"/></legend></h2>
       </td>
      </tr>
      <tr>
        <td>
              Variables chosen to plot:
        </td>
        <td>
              <xsl:call-template name="daterange"/>
       </td>
      </tr>
      <tr>
       <td><legend>Select Bounding Box:</legend></td>
       <td align="left" colspan="1">
      <table border="1">
        <xsl:call-template name="OrgSpatialPicker"/>
      </table>
    </td>
  </tr>
  <tr>
  <td align="left" colspan="1">
    <legend>Select Date Range: (UTC) </legend>
    <div class="hint">Format: YYYY-MM-DDTHH:MM::SSZ</div>
  </td>
  <td>
    <div id="startDateTimeContainer" class="dateTimeContainer">
      <xsl:element name="input">
         <xsl:attribute name="name">starttime</xsl:attribute>
         <xsl:attribute name="type">datetime</xsl:attribute>
         <xsl:attribute name="value"><xsl:value-of select="/root/@defStart"/></xsl:attribute>
         <xsl:attribute name="pattern">\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ</xsl:attribute>
         <xsl:attribute name="title">"YYYY-MM-DDTHH:MM:SSZ"</xsl:attribute>
      </xsl:element>
          <div id="dateRangeSeparator"> to </div>
      <xsl:element name="input">
         <xsl:attribute name="name">endtime</xsl:attribute>
         <xsl:attribute name="type">datetime</xsl:attribute>
         <xsl:attribute name="value"><xsl:value-of select="/root/@defEnd"/></xsl:attribute>
         <xsl:attribute name="pattern">\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ</xsl:attribute>
         <xsl:attribute name="title">"YYYY-MM-DDTHH:MM:SSZ"</xsl:attribute>
      </xsl:element>
    </div>
  </td>
 </tr>
 <tr>
<td align="center" colspan="2"></td></tr>
  <tr>
   <td align="center" colspan="2"><span id="sessionDataSelToolbarplotBTN" class="yui-button yui-button-button plotButton"><span class="first-child">
   <input style="background: url(&quot;../img/giovanni_icons.png&quot;) repeat scroll -5px -333px transparent; font-weight: bold; width: 250px;" type="submit" value="Plot Data" title="To generate a plot, fill out the form above and click this button!" /></span></span></td>
     </tr>
   </table>
  </form>
      <!--
      <table border="1">
        <xsl:call-template name="SpatialPicker"/>
      </table>
       -->

    <table>
      <tr>
        <td colspan="3" align="right">
          <xsl:call-template name="FeedbackButton"/>
         </td>
      </tr>
    </table>
<p/>
<p/>
    </table>
  </div>
  </xsl:template>

<xsl:template name="SpatialPicker">
 
 
       <tr>
        <td colspan="2"/>
                <td>North:</td><td><input type="text" name="North" value="90" /></td>
                <td colspan="2"/></tr><tr><td>West:</td><td><input type="text" name="West" value="-180" /></td>
                <td colspan="2"/><td>East:</td><td><input type="text" name="East" value="180" /></td></tr><tr>
                <td colspan="2"/><td>South:</td><td><input type="text" name="South" value="-90" /></td><td colspan="2"/>
        </tr>

</xsl:template>

<xsl:template name="OrgSpatialPicker">
  <tr>
   <td align="left" colspan="3">
    <div class="hint">Format: West, South, East, North </div>
   <input type="text" name="bbox" value="-180,-90.0,180.0,90.0" pattern="\S+" title="No spaces between coordinates" required="" />
   </td>
  </tr>
</xsl:template>


<xsl:template name="FeedbackButton">
    <address>
        <xsl:element name="a">
            <xsl:attribute name="href">mailto:gsfc-agiovanni-dev-disc@lists.nasa.gov?subject=Questions about NoScript Giovanni</xsl:attribute>
        Feedback
        </xsl:element>

    </address>
</xsl:template>

<xsl:template name="daterange">
           <table border="0">
             <tr>
              <td align="center" colspan="1">
                <xsl:value-of select="/root/@display1"/>
              </td>
              <td align="center" colspan="1">
                <xsl:value-of select="/root/@starttime1"/>
              </td>
              <td align="center" colspan="1">
                <xsl:value-of select="/root/@endtime1"/>
              </td>
             </tr>
             <tr>
              <td align="center" colspan="1">
                 <xsl:value-of select="/root/@display2"/>
             </td>
              <td align="center" colspan="1">
                <xsl:value-of select="/root/@starttime2"/>
              </td>
              <td align="center" colspan="1">
                <xsl:value-of select="/root/@endtime2"/>
              </td>
           </tr>
          </table>
</xsl:template>

</xsl:stylesheet>

