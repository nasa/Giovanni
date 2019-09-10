<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
xmlns:java="http://xml.apache.org/xslt/java" exclude-result-prefixes="java">

<xsl:output method="xml" version="1.0" indent="yes" />

<xsl:template match="dataField">
  <dataField>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldId" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldG3Id" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldActive" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldProductId" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldSdsName" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldShortName" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldLongName" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldAccessName" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataFieldAccessFormat" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataFieldAccessFormatVersion" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataFieldAccessMethod" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataFieldSld" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataFieldMeasurement" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldDescriptionUrl" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataFieldDiscipline" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldKeywords" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataFieldTags" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldSearchFilter" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldStandardName" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataFieldFillValueFieldName" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldUnits" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataFieldDestinationUnits" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldDeflationLevel" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./virtualDataFieldGenerator" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldVectorComponentNames" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldAccumulatable" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldInternal" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldInDb" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldState" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldLastExtracted" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldLastModified" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldLastPublished" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldMinValid" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldMaxValid" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldNominalMinValue" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldNominalMaxValue" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataFieldValuesDistribution" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="eraseValids">
    <xsl:with-param name="node" select="./dataFieldTimeIntvRepPos" />
    <xsl:with-param name="erase" select="./eraseValids" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldWavelengths" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldWavelengthUnits" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldDepths" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldDepthUnits" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldZDimensionName" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldZDimensionType" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldZDimensionUnits" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataFieldZDimensionValues" />
  </xsl:call-template>
  <xsl:apply-templates select= "./dataFieldPublishedBaselineInfo" />
  <!-- 
  <xsl:apply-templates select="./dataFieldId" />
  <xsl:apply-templates select="./dataFieldG3Id" />
  <xsl:apply-templates select="./dataFieldActive" />
  <xsl:apply-templates select="./dataFieldProductId" />
  <xsl:apply-templates select="./dataFieldSdsName" />
  <xsl:apply-templates select="./dataFieldShortName" />
  <xsl:apply-templates select="./dataFieldLongName" />
  <xsl:apply-templates select="./dataFieldAccessName" />
  <xsl:apply-templates select="./dataFieldAccessFormat" />
  <xsl:apply-templates select="./dataFieldAccessFormatVersion" />
  <xsl:apply-templates select="./dataFieldAccessMethod" />
  <xsl:apply-templates select="./dataFieldSld" />
  <xsl:apply-templates select="./dataFieldMeasurement" />
  <xsl:apply-templates select="./dataFieldDescriptionUrl" />
  <xsl:apply-templates select="./dataFieldDiscipline" />
  <xsl:apply-templates select="./dataFieldKeywords" />
  <xsl:apply-templates select="./dataFieldTags" />
  <xsl:apply-templates select="./dataFieldSearchFilter" />
  <xsl:apply-templates select="./dataFieldStandardName" />
  <xsl:apply-templates select="./dataFieldFillValueFieldName" />
  <xsl:apply-templates select="./dataFieldUnits" />
  <xsl:apply-templates select="./dataFieldDeflationLevel" />
  <xsl:apply-templates select="./virtualDataFieldGenerator" />
  <xsl:apply-templates select="./dataFieldVectorComponentNames" />
  <xsl:apply-templates select="./dataFieldAccumulatable" />
  <xsl:apply-templates select="./dataFieldInternal" />
  <xsl:apply-templates select="./dataFieldInDb" />
  <xsl:apply-templates select="./dataFieldState" />
  <xsl:apply-templates select="./dataFieldLastExtracted" />
  <xsl:apply-templates select="./dataFieldLastModified" />
  <xsl:apply-templates select="./dataFieldLastPublished" />
  <xsl:apply-templates select="./dataFieldMinValid" />
  <xsl:apply-templates select="./dataFieldMaxValid" />
  <xsl:apply-templates select="./dataFieldWavelengths" />
  <xsl:apply-templates select="./dataFieldWavelengthUnits" />
  <xsl:apply-templates select="./dataFieldDepths" />
  <xsl:apply-templates select="./dataFieldDepthUnits" />
  <xsl:apply-templates select="./dataFieldZDimensionName" />
  <xsl:apply-templates select="./dataFieldZDimensionType" />
  <xsl:apply-templates select="./dataFieldZDimensionUnits" />
  <xsl:apply-templates select="./dataFieldZDimensionValues" />
  <xsl:apply-templates select="./dataFieldNominalMinValue" />
  <xsl:apply-templates select="./dataFieldNominalMaxValue" />
  <xsl:apply-templates select="./dataFieldValuesDistribution" />
  -->
  </dataField>
</xsl:template>

<!--
<xsl:template match="dataFieldId">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldG3Id">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldActive">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldProductId">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldSdsName">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldShortName">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldLongName">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldAccessName">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldAccessFormat">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldAccessFormatVersion">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldAccessMethod">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldSld">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldMeasurement">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldDescriptionUrl">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldDiscipline">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldKeywords">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldTags">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldSearchFilter">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldStandardName">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldFillValueFieldName">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldUnits">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldDeflationLevel">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="virtualDataFieldGenerator">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldVectorComponentNames">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldAccumulatable">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldInternal">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldInDb">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldState">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldLastExtracted">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldLastModified">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldLastPublished">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldMinValid">
  <dataFieldMinValid>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <xsl:copy-of select="./multiplicity"/>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldMinValid>
</xsl:template>

<xsl:template match="dataFieldMaxValid">
  <dataFieldMaxValid>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <xsl:copy-of select="./multiplicity"/>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldMaxValid>
</xsl:template>

<xsl:template match="dataFieldValuesDistribution">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="dataFieldWavelengths">
  <dataFieldWavelengths>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <xsl:copy-of select="./multiplicity"/>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldWavelengths>
</xsl:template>

<xsl:template match="dataFieldWavelengthUnits">
  <dataFieldWavelengthUnits>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <multiplicity>one</multiplicity>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldWavelengthUnits>
</xsl:template>

<xsl:template match="dataFieldDepths">
  <dataFieldDepths>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <xsl:copy-of select="./multiplicity"/>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldDepths>
</xsl:template>

<xsl:template match="dataFieldDepthUnits">
  <dataFieldDepthUnits>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <xsl:copy-of select="./multiplicity"/>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldDepthUnits>
</xsl:template>

<xsl:template match="dataFieldZDimensionName">
  <dataFieldZDimensionName>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <xsl:copy-of select="./multiplicity"/>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldZDimensionName>
</xsl:template>

<xsl:template match="dataFieldZDimensionType">
  <dataFieldZDimensionType>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <xsl:copy-of select="./multiplicity"/>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldZDimensionType>
</xsl:template>

<xsl:template match="dataFieldZDimensionUnits">
  <dataFieldZDimensionUnits>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <xsl:copy-of select="./multiplicity"/>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldZDimensionUnits>
</xsl:template>

<xsl:template match="dataFieldZDimensionValues">
  <dataFieldZDimensionValues>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <xsl:copy-of select="./multiplicity"/>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldZDimensionValues>
</xsl:template>
<xsl:template match="dataFieldNominalMinValue">
  <dataFieldNominalMinValue>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <xsl:copy-of select="./multiplicity"/>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldNominalMinValue>
</xsl:template>

<xsl:template match="dataFieldNominalMaxValue">
  <dataFieldNominalMaxValue>
    <xsl:copy-of select="./type"/>
    <xsl:copy-of select="./label"/>
    <xsl:copy-of select="./multiplicity"/>
    <xsl:copy-of select="./constraints"/>
    <xsl:copy-of select="./example"/>
    <xsl:copy-of select="./value"/>
  </dataFieldNominalMaxValue>
</xsl:template>
-->

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

<xsl:template match="dataFieldPublishedBaselineInfo">
  <xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
