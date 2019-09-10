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
<legend>Select a Plot Type to begin your Analysis</legend>
<p/>
    Variables chosen to plot:
            <xsl:value-of select="/root/@display1"/> 
            <xsl:element name="input">
                    <xsl:attribute name="type">hidden</xsl:attribute>
                    <xsl:attribute name="value"><xsl:value-of select="/root/@variable1"/></xsl:attribute>
            </xsl:element>
            <xsl:if test="/root/@variable2">
              <xsl:text> and </xsl:text><xsl:value-of select="/root/@display2"/> 
              <xsl:element name="input">
                    <xsl:attribute name="type">hidden</xsl:attribute>
                    <xsl:attribute name="value"><xsl:value-of select="/root/@variable2"/></xsl:attribute>
              </xsl:element>
            </xsl:if>
    <table align="center">
    <xsl:for-each select="//Services/Plot">
      <tr>
        <td>
            <xsl:element name="a">
                    <xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
                    <xsl:attribute name="title"><xsl:value-of select="'link to create plot page'"/></xsl:attribute>
                    <xsl:value-of select="./@label"/>
             </xsl:element>
        </td>
        <td>
            <xsl:value-of select="./@desc"/>
        </td>
        <td>
            <xsl:element name="a">
                    <xsl:attribute name="href"><xsl:value-of select="@info"/></xsl:attribute>
                    <xsl:attribute name="title"><xsl:value-of select="'information page'"/></xsl:attribute>
                    Info Page
             </xsl:element>
        </td>
      </tr>
    </xsl:for-each>
      <tr>
        <td colspan="3" align="right">
          <xsl:call-template name="FeedbackButton"/>
         </td>
      </tr>
    </table>
<p/>
<p/>
  </div>
  </xsl:template>


<xsl:template name="FeedbackButton">
    <address>
        <xsl:element name="a">
            <xsl:attribute name="href">mailto:gsfc-agiovanni-dev-disc@lists.nasa.gov?subject=Questions about NoScript Giovanni</xsl:attribute>
        Feedback
        </xsl:element>

    </address>
</xsl:template>

</xsl:stylesheet>

