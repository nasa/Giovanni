<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output media-type="text/xml" method="xml" indent="yes"/>

  <xsl:template match="/">
    <update>
      <add overwrite="true">
        <xsl:apply-templates select="response/result/doc"/>
      </add>
    </update>
  </xsl:template>

  <!-- Skip fields that were added via copyField or for bookkeeping -->
  <xsl:template match="doc/*[@name='dataFieldLongNameText']" priority="100"/>
  <xsl:template match="doc/*[@name='dataFieldKeywordsString']" priority="100"/>
  <xsl:template match="doc/*[@name='dataFieldKeywordsText']" priority="100"/>
  <xsl:template match="doc/*[@name='specialFeatures']" priority="100"/>
  <xsl:template match="doc/*[@name='_version_']" priority="100"/>
  <xsl:template match="doc/*[@name='dataFieldLastIndexed']" priority="100"/>
  
  <xsl:template match="doc">
     <doc>
      <xsl:apply-templates select="*"/>
    </doc>
  </xsl:template>

  <!--
      Convert each element contained in an arr to a field whose name
      is the name of the arr.
  -->
  <xsl:template match="doc/arr" priority="99">
    <xsl:variable name="fname" select="@name"/>
    <xsl:for-each select="*">
      <xsl:element name="field">
	<xsl:attribute name="name">
	  <xsl:value-of select="$fname" />
	</xsl:attribute>
	<xsl:value-of select="." />
      </xsl:element>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="doc/*">
    <xsl:variable name="fname" select="@name"/>
    <xsl:element name="field">
      <xsl:attribute name="name">
	<xsl:value-of select="$fname"/>
      </xsl:attribute>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="*"/>
</xsl:stylesheet>
