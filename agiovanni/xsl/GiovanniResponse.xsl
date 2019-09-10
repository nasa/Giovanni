<?xml version="1.0" encoding="utf-8"?>
<!-- $Id: GiovanniResponse.xsl,v 1.12 2015/07/10 14:05:30 rstrub Exp $ -->
<!-- -@@@  $Name:  $ -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="iso-8859-1" indent="yes" />
<!--
              doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
              doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>
-->
  <xsl:template match = "/">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <xsl:text>&#10;</xsl:text>
      <head><title>Giovanni Response</title>
	  </head>
      <xsl:text>&#10;</xsl:text>
      <body>
        <xsl:apply-templates />
      </body>
      <xsl:text>&#10;</xsl:text>
    </html>
  </xsl:template>

  <xsl:template match="session">
    <xsl:for-each select="resultset">
      <xsl:for-each select="result">
        <xsl:text>&#10;</xsl:text>
        <div>
        <xsl:text>&#10;</xsl:text>
        <xsl:choose>
          <xsl:when test="normalize-space(status/code) != '0'">
            <h3><xsl:value-of select="normalize-space(status/message)" /></h3>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="data/fileGroup/dataFile/image">
                <table width="100%" border="1">
                  <xsl:text>&#10;</xsl:text>
                  <tr>
                    <xsl:text>&#10;</xsl:text>
                    <td><strong>Status: </strong><xsl:value-of select="normalize-space(status/message)" /></td>
                  </tr>
                  <xsl:text>&#10;</xsl:text>
                  <xsl:for-each select="data/fileGroup">
                    <xsl:for-each select="dataFile">
                      <tr>
                        <xsl:text>&#10;</xsl:text>
                        <td>
                          <table width="100%" border="0">
                            <xsl:text>&#10;</xsl:text>
                            <tr>
                              <xsl:text>&#10;</xsl:text>
                              <!-- <td align='center'> -->
                              <xsl:element name="td">
                                <xsl:attribute name="align">center</xsl:attribute>
                                <xsl:attribute name="colspan"><xsl:value-of select="count(image)"/></xsl:attribute>
                                <strong><xsl:text>Data File: </xsl:text></strong>
                              <xsl:element name="a"><xsl:attribute name="href"><xsl:value-of select="normalize-space(dataUrl)" /></xsl:attribute><xsl:value-of select="dataUrl/@label" /></xsl:element></xsl:element>
                              <!-- </td> -->
                            </tr>
                            <xsl:text>&#10;</xsl:text>
                            <tr>
                              <xsl:text>&#10;</xsl:text>
                              <xsl:for-each select="image">
                                <td align='center'>
                                  <xsl:element name="img"><xsl:attribute name="src"><xsl:value-of select="normalize-space(src)" /></xsl:attribute></xsl:element>
                                </td>
                              </xsl:for-each>
                              </tr><xsl:text>&#10;</xsl:text>
                          </table>
                          <xsl:text>&#10;</xsl:text>
                        </td>
                      </tr>
                      <xsl:text>&#10;</xsl:text>
                    </xsl:for-each>
                  </xsl:for-each>
                  <tr>
                    <xsl:text>&#10;</xsl:text>
                    <td>
                      <xsl:choose>
    				   <xsl:when test="contains(//referer,'noscript')">
                        <xsl:element name="a"><xsl:attribute name="href"><xsl:value-of select="substring-after(//lineage,'daac-bin/')" /></xsl:attribute><xsl:text>Show Lineage</xsl:text></xsl:element>
                       </xsl:when>
                       <xsl:otherwise>
                        <xsl:element name="a"><xsl:attribute name="href"><xsl:value-of select="normalize-space(lineage)" /></xsl:attribute><xsl:text>Show Lineage</xsl:text></xsl:element>
                       </xsl:otherwise>
                      </xsl:choose>
                    </td>
                  </tr>
                  <xsl:text>&#10;</xsl:text>
                </table>
              </xsl:when>
              <xsl:otherwise>
                <xsl:choose>
                  <xsl:when test="status/percentComplete = '100'">
                    <xsl:text>&#10;</xsl:text>
                    <h3><xsl:value-of select="normalize-space(status/message)" /></h3>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>&#10;</xsl:text>
                    <table width="100%" border="0">
                      <xsl:text>&#10;</xsl:text>
                      <tr>
                        <xsl:text>&#10;</xsl:text>
                        <td><strong>Status: </strong><xsl:value-of select="normalize-space(status/message)" /></td>
                      </tr>
                      <xsl:text>&#10;</xsl:text>
                      <tr>
                        <xsl:text>&#10;</xsl:text>
                        <td><strong>Percent Complete: </strong><xsl:value-of select="format-number(status/percentComplete,'###.#')" /></td>
                      </tr>
                      <xsl:text>&#10;</xsl:text>
                      <tr>
                        <xsl:text>&#10;</xsl:text>
                        <td>
                       <xsl:choose>
    					<xsl:when test="contains(//referer,'noscript') or contains(//message, 'workflow')">
        <xsl:element name="meta">
		 <xsl:attribute  name="http-equiv">refresh</xsl:attribute>
<xsl:attribute  name="content">5;url=<xsl:text>../daac-bin/service_manager.pl?session=</xsl:text><xsl:value-of select="../../@id" /><xsl:text>&amp;resultset=</xsl:text><xsl:value-of select="../@id" /><xsl:text>&amp;result=</xsl:text><xsl:value-of select="./@id" /></xsl:attribute></xsl:element>
                       	</xsl:when>
                       	<xsl:otherwise>
<xsl:element name="a"><xsl:attribute name="href"><xsl:text>../daac-bin/service_manager.pl?session=</xsl:text><xsl:value-of select="../../@id" /><xsl:text>&amp;resultset=</xsl:text><xsl:value-of select="../@id" /><xsl:text>&amp;result=</xsl:text><xsl:value-of select="./@id" /></xsl:attribute>Refresh</xsl:element>
                        </xsl:otherwise>
                       </xsl:choose>
						</td>
                      </tr>
                      <xsl:text>&#10;</xsl:text>
                    </table>
                    <xsl:text>&#10;</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
        </div>
        <xsl:text>&#10;</xsl:text>
      </xsl:for-each>
    </xsl:for-each>
    <xsl:if test="contains(//referer,'noscript') or contains(//message, 'workflow')">
      <xsl:call-template name="FeedbackButton"/>
    </xsl:if>
  </xsl:template>

<xsl:template name="FeedbackButton">
    Please let us know:
    <address>
        <xsl:element name="a">
            <xsl:attribute name="href">mailto:gsfc-agiovanni-dev-disc@lists.nasa.gov?subject=NoScript Giovanni Feedback&amp;body=session=<xsl:value-of  select="substring-after(//lineage,'result=')"/></xsl:attribute>
        Feedback
        </xsl:element>

    </address>
</xsl:template>

</xsl:stylesheet>
