<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="utf-8" omit-xml-declaration="yes"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>


  <xsl:template match="/">
    <xsl:apply-templates select="Variables"/>
  </xsl:template>
  <xsl:template name="Variables" match = "/">
<div  align="center" class="pageTitle">
</div>
<p/>

  <form action="../../giovanni/daac-bin/noscript.cgi">
                <xsl:value-of select="/root/FakePlot"/>

              <xsl:if test="/root/PlotID != ''">
                <xsl:element name="input">
                  <xsl:attribute name="type">hidden</xsl:attribute>
                  <xsl:attribute name="value"> <xsl:value-of select="/root/PlotID"/></xsl:attribute>
                  <xsl:attribute name="name"> <xsl:value-of select="'service'"/></xsl:attribute>
                </xsl:element>
              </xsl:if>
              <xsl:element name="input">
                <xsl:attribute name="type">hidden</xsl:attribute>
                <xsl:attribute name="name">portal</xsl:attribute>
                <xsl:attribute name="value">GIOVANNI</xsl:attribute>
              </xsl:element>
              <xsl:element name="input">
                <xsl:attribute name="type">hidden</xsl:attribute>
                <xsl:attribute name="name">variable</xsl:attribute>
                <xsl:attribute name="value"><xsl:value-of select="/root/@previous_variable"/></xsl:attribute>
              </xsl:element>
    
    <table align="center" border="1" width="80%" style="background-color:#ccddee">
       <tr>
        <td align="center" colspan="2">
          <xsl:call-template name="SubmitButton"/>
        </td>
      </tr>
      <tr >
         <xsl:text disable-output-escaping="yes">&#10;</xsl:text> 
        <td align="left" colspan="1">
          <legend>The first variable you selected was: <xsl:value-of select="/root/@previous_display"/></legend> 
        </td>
      </tr>
      <tr>
         <xsl:text disable-output-escaping="yes">&#10;</xsl:text> 
        <td align="center" colspan="2">
          <xsl:call-template name="NewVariablePicker"/>
          <xsl:call-template name="D3VariablePicker"/>
        </td>
      </tr>
 	  <tr>
        <td align="center" colspan="2">
          <xsl:call-template name="SubmitButton"/>
        </td>
        <td align="center" colspan="2">
          <xsl:call-template name="FeedbackButton"/>
        </td>
      </tr>
    </table>
  </form>
  </xsl:template>


<xsl:template name="FeedbackButton">
    <address>
        <xsl:element name="a">
			<xsl:attribute name="href">mailto:gsfc-agiovanni-dev-disc@lists.nasa.gov?subject=Problems with <xsl:value-of select="/root/PlotName"/>&amp;body=Plot I was running:<xsl:value-of select="/root/@desc"/></xsl:attribute>	
        Feedback
        </xsl:element>
       
    </address>
</xsl:template>



<xsl:template name="SubmitButton">
           <span id="sessionDataSelToolbarplotBTN" class="yui-button yui-button-button plotButton">
            <span class="first-child">
            <xsl:element name="input">
               <xsl:attribute name="style">'background: url("../img/giovanni_icons.png") repeat scroll -5px -333px transparent; font-weight: bold; width: 250px;'</xsl:attribute>
               <xsl:attribute name="type">submit</xsl:attribute>
               <xsl:attribute name="value"><xsl:value-of select="/root/@buttonval"/></xsl:attribute>
               <xsl:attribute name="title">To generate a plot, fill out the form above and click this button!</xsl:attribute>
              </xsl:element>
            </span>
          </span>
</xsl:template>


<xsl:template name="DatePicker">
         <div id="startDateTimeContainer" class="dateTimeContainer">
         <input  type="date" name="starttime" value="2010-01-01T00:00:00Z" pattern="\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ" title="YYYY-MM-DDTHH:MM:SSZ" min="1979-12-31" required=""/> 
         <div id="dateRangeSeparator"> to </div>
         <input  type="date"  name="endtime"   value="2010-01-04T23:59:59Z" pattern="\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ" title="YYYY-MM-DDTHH:MM:SSZ" min="1979-12-31" required=""/> 
         </div>
</xsl:template>


<xsl:template name="NewVariablePicker">
      <xsl:for-each select="/root">
       <table border="0">
         <xsl:text disable-output-escaping="yes">&#10;</xsl:text> 
           <xsl:for-each select="Variable">
           <tr>
            <td colspan="2">
             <xsl:element name="input">
             	<xsl:attribute name="name">variable2</xsl:attribute>
             	<xsl:attribute name="type">radio</xsl:attribute>
                <xsl:attribute name="value"><xsl:value-of select="./@dataFieldName"/></xsl:attribute>
                <xsl:value-of select="."/>
             </xsl:element>
           </td>
          </tr>
          </xsl:for-each>
         </table>
     </xsl:for-each>
      
</xsl:template>

<xsl:template name="D3VariablePicker">
   <fieldset class="field_set">
    <legend>3D Variables</legend>
      <xsl:for-each select="/root">
       <table border="0">
         <xsl:text disable-output-escaping="yes">&#10;</xsl:text>
           <xsl:for-each select="D3Variable">
           <tr>
            <td colspan="2">
             <xsl:element name="input">
                <xsl:attribute name="name">variable2</xsl:attribute>
                <xsl:attribute name="type">radio</xsl:attribute>
                <xsl:attribute name="value"><xsl:value-of select="./@dataFieldName"/></xsl:attribute>
                <xsl:value-of select="."/>
             </xsl:element>
           </td>
          </tr>
          </xsl:for-each>
         </table>
     </xsl:for-each>
  </fieldset>
</xsl:template>

<xsl:template name="VariablePicker">
      <xsl:for-each select="/root/PlotSetup">
         <xsl:text disable-output-escaping="yes">&#10;</xsl:text> 
        <xsl:choose>
         <xsl:when test="./@required">
            <xsl:element name="select">
             <xsl:attribute name="name">data</xsl:attribute>
             <xsl:attribute name="size">5</xsl:attribute>
             <xsl:attribute name="required"/>
             <xsl:attribute name="id"><xsl:value-of select="/root/PlotSetup/@selectid"/></xsl:attribute>
                <option>
                  <xsl:attribute name="value"></xsl:attribute>
                </option>
              <xsl:for-each select="Variable">
                  <option>
                   <xsl:attribute name="value"><xsl:value-of select="."/></xsl:attribute>
                   <xsl:value-of select="."/>
                 </option>
              </xsl:for-each>
           </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="select">
             <xsl:attribute name="name">data</xsl:attribute>
             <xsl:attribute name="size">5</xsl:attribute>
             <xsl:attribute name="id"><xsl:value-of select="/root/PlotSetup/@selectid"/></xsl:attribute>
                <option>
                  <xsl:attribute name="value"></xsl:attribute>
                </option>
              <xsl:for-each select="Variable">
                  <option>
                   <xsl:attribute name="value"><xsl:value-of select="."/></xsl:attribute>
                   <xsl:value-of select="."/>
                 </option>
              </xsl:for-each>
           </xsl:element>
         </xsl:otherwise>
        </xsl:choose>
     </xsl:for-each>
</xsl:template>
<xsl:template name="SpatialPicker">
               <input type="text" name="bbox" value="-180,-90.0,180.0,90.0" pattern="\S+" title="No spaces between coordinates" required=""/>
</xsl:template>
<xsl:template name="oldSpatialPicker">
            <table border="0">
             <tr><td colspan="2"/>
                <td>North:</td><td><input type="text" name="SUB_LATMAX" value="90.0" /></td><td colspan="2"/></tr>
             <tr><td>West:</td><td><input type="text" name="SUB_LONMIN" value="-180.0" /></td>
             <td colspan="2"/><td>East:</td><td>
             <input type="text" name="SUB_LONMAX" value="180.0" /></td></tr><tr>
             <td colspan="2"/><td>South:</td><td><input type="text" name="SUB_LATMIN" value="-90" /></td><td colspan="2"/>
             </tr></table>
</xsl:template>
</xsl:stylesheet>

