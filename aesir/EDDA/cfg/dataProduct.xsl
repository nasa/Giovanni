<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
xmlns:java="http://xml.apache.org/xslt/java" exclude-result-prefixes="java">

<xsl:output method="xml" version="1.0" indent="yes" />

<xsl:template match="dataProduct">
  <dataProduct>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductId" />
  </xsl:call-template>
  <xsl:call-template name="dataProductIdentifiers">
    <xsl:with-param name="node" select="./dataProductIdentifiers" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductDescriptionUrl" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataProductProcessingLevel" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <!--
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataProductDataCenter" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  -->
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductDataCenter" />
  </xsl:call-template>
  <xsl:call-template name="dataProductPlatform">
    <xsl:with-param name="node" select="./dataProductPlatform" />
  </xsl:call-template>
  <xsl:call-template name="dataProductInstrument">
    <xsl:with-param name="node" select="./dataProductInstrument" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataProductPlatformInstrument" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataProductObservation" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="dataProductSpatialResolution">
    <xsl:with-param name="node" select="./dataProductSpatialResolution" />
  </xsl:call-template>
  <xsl:call-template name="dataProductSpatialCoverage">
    <xsl:with-param name="node" select="./dataProductSpatialCoverage" />
  </xsl:call-template>
  <xsl:call-template name="dataProductTemporalCoverage">
    <xsl:with-param name="node" select="./dataProductTemporalCoverage" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSearchIntervalDays" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductOsddUrl" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSampleGranuleUrl" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductOpendapUrl" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataProductResponseFormat" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataProductSpecialFeatures" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductInternal" />
  </xsl:call-template>
  <xsl:call-template name="basicNoNorm">
    <xsl:with-param name="node" select="./dataProductDataFieldIds" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductCanAddNewFields" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductGcmdLastRevisionDate" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductLastModified" />
  </xsl:call-template>
  </dataProduct>
</xsl:template>


<xsl:template name="normalize">
  <xsl:param name="nodeList" />
  <xsl:for-each select="$nodeList">
    <xsl:element name="{local-name()}">
      <!--
      <xsl:for-each select="@*">
        <xsl:attribute name="{local-name()}">
          <xsl:value-of select="normalize-space(.)" />
        </xsl:attribute>
      </xsl:for-each>
      -->
      <xsl:value-of select="normalize-space(text())" />
      <!--
      <xsl:call-template name="normalize">
        <xsl:with-param name="nodeList" select="./child::*" />
      </xsl:call-template>
      -->
    </xsl:element>
  </xsl:for-each>
</xsl:template>

<xsl:template name="basic">
  <xsl:param name="node" />
  <xsl:element name="{local-name($node)}">
    <xsl:copy-of select="$node/type"/>
    <xsl:copy-of select="$node/label"/>
    <xsl:copy-of select="$node/multiplicity"/>
    <xsl:copy-of select="$node/valids"/>
    <xsl:call-template name="constraints">
      <xsl:with-param name="node" select="$node/constraints" />
    </xsl:call-template>
    <xsl:copy-of select="$node/example"/>
    <!-- <xsl:copy-of select="$node/value"/> -->
    <xsl:call-template name="normalize">
      <xsl:with-param name="nodeList" select="$node/value" />
    </xsl:call-template>
  </xsl:element>
</xsl:template>

<xsl:template name="basicNoNorm">
  <xsl:param name="node" />
  <xsl:element name="{local-name($node)}">
    <xsl:copy-of select="$node/type"/>
    <xsl:copy-of select="$node/label"/>
    <xsl:copy-of select="$node/multiplicity"/>
    <xsl:copy-of select="$node/valids"/>
    <xsl:call-template name="constraints">
      <xsl:with-param name="node" select="$node/constraints" />
    </xsl:call-template>
    <xsl:copy-of select="$node/example"/>
    <xsl:copy-of select="$node/value"/>
  </xsl:element>
</xsl:template>

<xsl:template name="dataProductIdentifiers">
  <xsl:param name="node" />
  <xsl:element name="{local-name($node)}">
    <xsl:copy-of select="$node/type"/>
    <xsl:copy-of select="$node/label"/>
    <xsl:copy-of select="$node/multiplicity"/>
    <xsl:element name="value">
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductDataSetId" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductGcmdEntryId" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductShortName" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductVersion" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductLongName" />
      </xsl:call-template>
    </xsl:element>
  </xsl:element>
</xsl:template>

<xsl:template name="dataProductPlatform">
  <xsl:param name="node" />
  <xsl:element name="{local-name($node)}">
    <xsl:copy-of select="$node/type"/>
    <xsl:copy-of select="$node/label"/>
    <xsl:copy-of select="$node/multiplicity"/>
    <xsl:element name="value">
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductPlatformShortName" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductPlatformLongName" />
      </xsl:call-template>
    </xsl:element>
  </xsl:element>
</xsl:template>

<xsl:template name="dataProductInstrument">
  <xsl:param name="node" />
  <xsl:element name="{local-name($node)}">
    <xsl:copy-of select="$node/type"/>
    <xsl:copy-of select="$node/label"/>
    <xsl:copy-of select="$node/multiplicity"/>
    <xsl:element name="value">
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductInstrumentShortName" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductInstrumentLongName" />
      </xsl:call-template>
    </xsl:element>
  </xsl:element>
</xsl:template>

<xsl:template name="dataProductSpatialResolution">
  <xsl:param name="node" />
  <xsl:element name="{local-name($node)}">
    <xsl:copy-of select="$node/type"/>
    <xsl:copy-of select="$node/label"/>
    <xsl:copy-of select="$node/multiplicity"/>
    <xsl:element name="value">
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductSpatialResolutionLatitude" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductSpatialResolutionLongitude" />
      </xsl:call-template>
      <xsl:call-template name="eraseValids">
        <xsl:with-param name="node" select="$node/value/dataProductSpatialResolutionUnits" />
        <xsl:with-param name="erase" select="./eraseValids" />
      </xsl:call-template>
    </xsl:element>
  </xsl:element>
</xsl:template>

<xsl:template name="dataProductSpatialCoverage">
  <xsl:param name="node" />
  <xsl:element name="{local-name($node)}">
    <xsl:copy-of select="$node/type"/>
    <xsl:copy-of select="$node/label"/>
    <xsl:copy-of select="$node/multiplicity"/>
    <xsl:element name="value">
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductWest" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductNorth" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductEast" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductSouth" />
      </xsl:call-template>
    </xsl:element>
  </xsl:element>
</xsl:template>

<xsl:template name="dataProductTemporalCoverage">
  <xsl:param name="node" />
  <xsl:element name="{local-name($node)}">
    <xsl:copy-of select="$node/type"/>
    <xsl:copy-of select="$node/label"/>
    <xsl:copy-of select="$node/multiplicity"/>
    <xsl:element name="value">
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductBeginDateTime" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductEndDateTime" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductEndDateTimeLocked" />
      </xsl:call-template>
      <xsl:call-template name="eraseValids">
        <xsl:with-param name="node" select="$node/value/dataProductTimeFrequency" />
        <xsl:with-param name="erase" select="./eraseValids" />
      </xsl:call-template>
      <xsl:call-template name="eraseValids">
        <xsl:with-param name="node" select="$node/value/dataProductTimeInterval" />
        <xsl:with-param name="erase" select="./eraseValids" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductStartTimeOffset" />
      </xsl:call-template>
      <xsl:call-template name="basic">
        <xsl:with-param name="node" select="$node/value/dataProductEndTimeOffset" />
      </xsl:call-template>
    </xsl:element>
  </xsl:element>
</xsl:template>

<xsl:template name="eraseValids">
  <xsl:param name="node" />
  <xsl:param name="erase" />
  <xsl:element name="{local-name($node)}">
    <xsl:copy-of select="$node/type"/>
    <xsl:copy-of select="$node/label"/>
    <xsl:copy-of select="$node/multiplicity"/>
    <xsl:choose>
      <xsl:when test="$erase">
        <xsl:element name="valids"></xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$node/valids"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:call-template name="constraints">
      <xsl:with-param name="node" select="$node/constraints" />
    </xsl:call-template>
    <xsl:copy-of select="$node/example"/>
    <!-- <xsl:copy-of select="$node/value"/> -->
    <xsl:call-template name="normalize">
      <xsl:with-param name="nodeList" select="$node/value" />
    </xsl:call-template>
  </xsl:element>
</xsl:template>

<xsl:template name="constraints">
  <xsl:param name="node" />
  <xsl:element name="constraints">
    <xsl:copy-of select="$node/required"/>
    <xsl:copy-of select="$node/editable"/>
    <xsl:copy-of select="$node/regex"/>
    <xsl:copy-of select="$node/validationText"/>
    <xsl:copy-of select="$node/maxlength"/>
  </xsl:element>
</xsl:template>

</xsl:stylesheet>
