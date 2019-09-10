<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
xmlns:java="http://xml.apache.org/xslt/java" exclude-result-prefixes="java">

<xsl:output method="xml" version="1.0" indent="yes" />

<xsl:template match="dataField">
  <dataField>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldId" />
    <xsl:with-param name="nodeName" select="'dataFieldId'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldG3Id" />
    <xsl:with-param name="nodeName" select="'dataFieldG3Id'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldActive" />
    <xsl:with-param name="nodeName" select="'dataFieldActive'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldProductId" />
    <xsl:with-param name="nodeName" select="'dataFieldProductId'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldSdsName" />
    <xsl:with-param name="nodeName" select="'dataFieldSdsName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldShortName" />
    <xsl:with-param name="nodeName" select="'dataFieldShortName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldLongName" />
    <xsl:with-param name="nodeName" select="'dataFieldLongName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldAccessName" />
    <xsl:with-param name="nodeName" select="'dataFieldAccessName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldAccessFormat" />
    <xsl:with-param name="nodeName" select="'dataFieldAccessFormat'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldAccessFormatVersion" />
    <xsl:with-param name="nodeName" select="'dataFieldAccessFormatVersion'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldAccessMethod" />
    <xsl:with-param name="nodeName" select="'dataFieldAccessMethod'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldSld" />
    <xsl:with-param name="nodeName" select="'dataFieldSld'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldMeasurement" />
    <xsl:with-param name="nodeName" select="'dataFieldMeasurement'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldDescriptionUrl" />
    <xsl:with-param name="nodeName" select="'dataFieldDescriptionUrl'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldDiscipline" />
    <xsl:with-param name="nodeName" select="'dataFieldDiscipline'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldKeywords" />
    <xsl:with-param name="nodeName" select="'dataFieldKeywords'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldTags" />
    <xsl:with-param name="nodeName" select="'dataFieldTags'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldSearchFilter" />
    <xsl:with-param name="nodeName" select="'dataFieldSearchFilter'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldStandardName" />
    <xsl:with-param name="nodeName" select="'dataFieldStandardName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldFillValueFieldName" />
    <xsl:with-param name="nodeName" select="'dataFieldFillValueFieldName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldUnits" />
    <xsl:with-param name="nodeName" select="'dataFieldUnits'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldDestinationUnits" />
    <xsl:with-param name="nodeName" select="'dataFieldDestinationUnits'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldDeflationLevel" />
    <xsl:with-param name="nodeName" select="'dataFieldDeflationLevel'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./virtualDataFieldGenerator" />
    <xsl:with-param name="nodeName" select="'virtualDataFieldGenerator'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldVectorComponentNames" />
    <xsl:with-param name="nodeName" select="'dataFieldVectorComponentNames'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldAccumulatable" />
    <xsl:with-param name="nodeName" select="'dataFieldAccumulatable'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldInternal" />
    <xsl:with-param name="nodeName" select="'dataFieldInternal'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldInDb" />
    <xsl:with-param name="nodeName" select="'dataFieldInDb'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldState" />
    <xsl:with-param name="nodeName" select="'dataFieldState'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldLastExtracted" />
    <xsl:with-param name="nodeName" select="'dataFieldLastExtracted'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldLastModified" />
    <xsl:with-param name="nodeName" select="'dataFieldLastModified'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldLastPublished" />
    <xsl:with-param name="nodeName" select="'dataFieldLastPublished'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldMinValid" />
    <xsl:with-param name="nodeName" select="'dataFieldMinValid'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldMaxValid" />
    <xsl:with-param name="nodeName" select="'dataFieldMaxValid'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldNominalMinValue" />
    <xsl:with-param name="nodeName" select="'dataFieldNominalMinValue'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldNominalMaxValue" />
    <xsl:with-param name="nodeName" select="'dataFieldNominalMaxValue'" />
  </xsl:call-template>
  <xsl:call-template name="default">
    <xsl:with-param name="node" select="./dataFieldValuesDistribution" />
    <xsl:with-param name="nodeName" select="'dataFieldValuesDistribution'" />
    <xsl:with-param name="defaultValue" select="'linear'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldTimeIntvRepPos" />
    <xsl:with-param name="nodeName" select="'dataFieldTimeIntvRepPos'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldWavelengths" />
    <xsl:with-param name="nodeName" select="'dataFieldWavelengths'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldWavelengthUnits" />
    <xsl:with-param name="nodeName" select="'dataFieldWavelengthUnits'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldDepths" />
    <xsl:with-param name="nodeName" select="'dataFieldDepths'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldDepthUnits" />
    <xsl:with-param name="nodeName" select="'dataFieldDepthUnits'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldZDimensionName" />
    <xsl:with-param name="nodeName" select="'dataFieldZDimensionName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldZDimensionType" />
    <xsl:with-param name="nodeName" select="'dataFieldZDimensionType'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldZDimensionUnits" />
    <xsl:with-param name="nodeName" select="'dataFieldZDimensionUnits'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldZDimensionValues" />
    <xsl:with-param name="nodeName" select="'dataFieldZDimensionValues'" />
  </xsl:call-template>
  </dataField>
</xsl:template>

<xsl:template name="basic">
  <xsl:param name="node" />
  <xsl:param name="nodeName" />
  <xsl:choose>
    <xsl:when test="$node">
      <xsl:element name="{local-name($node)}">
	<xsl:copy-of select="$node/value"/>
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="{$nodeName}">
	<xsl:element name="value"/>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="default">
  <xsl:param name="node" />
  <xsl:param name="nodeName" />
  <xsl:param name="defaultValue" />
  <xsl:choose>
    <xsl:when test="$node">
      <xsl:element name="{local-name($node)}">
	<xsl:choose>
	  <xsl:when test="$node/value">
	    <xsl:copy-of select="$node/value"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:element name="value">
	      <xsl:value-of select="$defaultValue" />
	    </xsl:element>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="{$nodeName}">
	<xsl:element name="value">
	  <xsl:value-of select="$defaultValue" />
	</xsl:element>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>

