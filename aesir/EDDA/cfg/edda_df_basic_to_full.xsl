<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
xmlns:java="http://xml.apache.org/xslt/java" exclude-result-prefixes="java">

<xsl:output method="xml" version="1.0" indent="yes" />


<xsl:template match="dataField">
  <dataField>
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
    <xsl:apply-templates select="./dataFieldDestinationUnits" />
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
    <xsl:apply-templates select="./dataFieldNominalMinValue" />
    <xsl:apply-templates select="./dataFieldNominalMaxValue" />
    <xsl:apply-templates select="./dataFieldValuesDistribution" />
    <xsl:apply-templates select="./dataFieldTimeIntvRepPos" />
    <xsl:apply-templates select="./dataFieldWavelengths" />
    <xsl:apply-templates select="./dataFieldWavelengthUnits" />
    <xsl:apply-templates select="./dataFieldDepths" />
    <xsl:apply-templates select="./dataFieldDepthUnits" />
    <xsl:apply-templates select="./dataFieldZDimensionName" />
    <xsl:apply-templates select="./dataFieldZDimensionType" />
    <xsl:apply-templates select="./dataFieldZDimensionUnits" />
    <xsl:apply-templates select="./dataFieldZDimensionValues" />
  </dataField>
</xsl:template>

<xsl:template name="wordTextField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="example"/>
  <type>text</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <regex>[a-zA-Z0-9_]+$</regex>
    <validationText>The value must consist only of letters, digits, underscores.</validationText>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="wordWithHyphenTextField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="maxlength"/>
  <xsl:param name="example"/>
  <type>text</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <regex>[a-zA-Z0-9_-]+$</regex>
    <validationText>The value must consist only of letters, digits, underscores, and hyphens.</validationText>
    <xsl:if test="$maxlength">
      <maxlength><xsl:value-of select="$maxlength"/></maxlength>
    </xsl:if>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="wordWithDotHyphenTextField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="example"/>
  <type>text</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <regex>[a-zA-Z0-9_.-]+$</regex>
    <validationText>The value must consist only of letters, digits, underscores, dots, and hyphens.</validationText>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="wordWithCommaSlashBracketsHyphenTextField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="example"/>
  <type>text</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <regex>[a-zA-Z0-9_/\[\]-]+$</regex>
    <validationText>The value must consist only of letters, digits, underscores, left brackets, right brackets, and hyphens.</validationText>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="basicNoValidsField">
  <xsl:param name="node"/>
  <xsl:param name="type"/>
  <xsl:param name="label"/>
  <xsl:param name="multiplicity"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="example"/>
  <type><xsl:value-of select="$type"/></type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity><xsl:value-of select="$multiplicity"/></multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="basicValidsField">
  <xsl:param name="node"/>
  <xsl:param name="type"/>
  <xsl:param name="label"/>
  <xsl:param name="multiplicity"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="example"/>
  <type><xsl:value-of select="$type"/></type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity><xsl:value-of select="$multiplicity"/></multiplicity>
  <valids/>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="listField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="multiplicity"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="example"/>
  <type>list</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity><xsl:value-of select="$multiplicity"/></multiplicity>
  <valids/>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="colorPaletteListField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="multiplicity"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <type>colorPaletteList</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>many</multiplicity>
  <valids/>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
  </constraints>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="urlField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="example"/>
  <type>url</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <regex>^(?:http|https|ftp)://[\w.-]+(?::\d+)?/[-\w\d/.#~\?]+$</regex>
    <validationText>The value must have the form of a URL.</validationText>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="booleanField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <type>boolean</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <regex>^true$|^false$</regex>
    <validationText>The value must be either 'true' or 'false'</validationText>
  </constraints>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="dateField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="multiplicity"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <type>datetime</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
  </constraints>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="shortnameTextField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <type>text</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <regex>[a-zA-Z0-9 _.,)(@/%+-]+$</regex>
    <validationText>The value must consist only of letters, digits, spaces, underscores, dots, commas, parentheses, @, slashes, percents, pluses, and hyphens.</validationText>
  </constraints>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="longnameTextField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="example"/>
  <type>text</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <regex>[a-zA-Z0-9 _.,:)(&amp;/%&gt;&lt;=+-]+$</regex>
    <validationText>The value must consist only of letters, digits, spaces, underscores, dots, commas, colons, parentheses, ampersands, slashes, percents, less-thans, greater-thans, equals, pluses, and hyphens.</validationText>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template match="dataFieldId">
  <dataFieldId>
    <xsl:call-template name="wordWithHyphenTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
      <xsl:with-param name="maxlength" select="'63'"/>
   </xsl:call-template>
  </dataFieldId>
</xsl:template>

<xsl:template match="dataFieldG3Id">
  <dataFieldG3Id>
    <xsl:call-template name="wordTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataFieldG3Id>
</xsl:template>

<xsl:template match="dataFieldActive">
  <dataFieldActive>
    <xsl:call-template name="booleanField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataFieldActive>
</xsl:template>

<xsl:template match="dataFieldProductId">
  <dataFieldProductId>
    <xsl:call-template name="wordWithDotHyphenTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
   </xsl:call-template>
  </dataFieldProductId>
</xsl:template>

<xsl:template match="dataFieldSdsName">
  <dataFieldSdsName>
    <xsl:call-template name="wordWithHyphenTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
      <xsl:with-param name="example" select="'Angstrom_Exponent_1_Ocean_QA_Mean'"/>
   </xsl:call-template>
  </dataFieldSdsName>
</xsl:template>

<xsl:template match="dataFieldShortName">
  <dataFieldShortName>
    <xsl:call-template name="shortnameTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataFieldShortName>
</xsl:template>

<xsl:template match="dataFieldLongName">
  <dataFieldLongName>
    <xsl:call-template name="longnameTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Long Name'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'Aerosol Optical Depth 550 nm (Dark Target), MODIS-Aqua, 1 x 1 deg.'"/>
    </xsl:call-template>
  </dataFieldLongName>
</xsl:template>

<xsl:template match="dataFieldAccessName">
  <dataFieldAccessName>
    <xsl:call-template name="wordWithCommaSlashBracketsHyphenTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Variable Name'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'Angstrom_Exponent_1_Ocean_QA_Mean'"/>
    </xsl:call-template>
  </dataFieldAccessName>
</xsl:template>

<xsl:template match="dataFieldAccessFormat">
  <dataFieldAccessFormat>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataFieldAccessFormat>
</xsl:template>

<xsl:template match="dataFieldAccessFormatVersion">
  <dataFieldAccessFormatVersion>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataFieldAccessFormatVersion>
</xsl:template>

<xsl:template match="dataFieldAccessMethod">
  <dataFieldAccessMethod>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataFieldAccessMethod>
</xsl:template>

<xsl:template match="dataFieldSld">
  <dataFieldSld>
    <xsl:call-template name="colorPaletteListField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Color Palettes'"/>
      <xsl:with-param name="multiplicity" select="'many'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataFieldSld>
</xsl:template>

<xsl:template match="dataFieldMeasurement">
  <dataFieldMeasurement>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Measurements'"/>
      <xsl:with-param name="multiplicity" select="'many'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataFieldMeasurement>
</xsl:template>

<xsl:template match="dataFieldDescriptionUrl">
  <dataFieldDescriptionUrl>
    <xsl:call-template name="urlField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Description URL'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'http://disc.sci.gsfc.nasa.gov/techlab/giovanni/G3_manual_parameter_appendix.shtml#Angstrom_ocean'"/>
    </xsl:call-template>
  </dataFieldDescriptionUrl>
</xsl:template>

<xsl:template match="dataFieldDiscipline">
  <dataFieldDiscipline>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Disciplines'"/>
      <xsl:with-param name="multiplicity" select="'many'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataFieldDiscipline>
</xsl:template>

<xsl:template match="dataFieldKeywords">
  <dataFieldKeywords>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Keywords'"/>
      <xsl:with-param name="multiplicity" select="'many'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataFieldKeywords>
</xsl:template>

<xsl:template match="dataFieldTags">
  <dataFieldTags>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Tags'"/>
      <xsl:with-param name="multiplicity" select="'many'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataFieldTags>
</xsl:template>

<xsl:template match="dataFieldSearchFilter">
  <dataFieldSearchFilter>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Granule Search Results Filter (regex)'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'.+Granule_name_string_specific_to_a_variable.*'"/>
    </xsl:call-template>
  </dataFieldSearchFilter>
</xsl:template>

<xsl:template match="dataFieldStandardName">
  <dataFieldStandardName>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'CF-1 Standard Name'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'air_temperature'"/>
    </xsl:call-template>
  </dataFieldStandardName>
</xsl:template>

<xsl:template match="dataFieldFillValueFieldName">
  <dataFieldFillValueFieldName>
    <xsl:call-template name="basicValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Name of fill value attribute'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataFieldFillValueFieldName>
</xsl:template>

<xsl:template match="dataFieldUnits">
  <dataFieldUnits>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Units'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'m/s'"/>
    </xsl:call-template>
  </dataFieldUnits>
</xsl:template>

<xsl:template match="dataFieldDestinationUnits">
  <dataFieldDestinationUnits>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Allowed Units Conversions'"/>
      <xsl:with-param name="multiplicity" select="'many'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'mm/day'"/>
    </xsl:call-template>
  </dataFieldDestinationUnits>
</xsl:template>

<xsl:template match="dataFieldDeflationLevel">
  <dataFieldDeflationLevel>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'Deflation Level'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'1'"/>
    </xsl:call-template>
  </dataFieldDeflationLevel>
</xsl:template>

<xsl:template match="virtualDataFieldGenerator">
  <virtualDataFieldGenerator>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Virtual data field generator'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'MAT1NXSLV_5_2_0_SLP=SLP/100.'"/>
    </xsl:call-template>
  </virtualDataFieldGenerator>
</xsl:template>

<xsl:template match="dataFieldVectorComponentNames">
  <dataFieldVectorComponentNames>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Vector Component Names'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'N10-m_above_ground_Zonal_wind_speed,N10-m_above_ground_Meridional_wind_speed'"/>
    </xsl:call-template>
  </dataFieldVectorComponentNames>
</xsl:template>

<xsl:template match="dataFieldAccumulatable">
  <dataFieldAccumulatable>
    <xsl:call-template name="booleanField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Can be accumulated?'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataFieldAccumulatable>
</xsl:template>

<xsl:template match="dataFieldInternal">
  <dataFieldInternal>
    <xsl:call-template name="booleanField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataFieldInternal>
</xsl:template>

<xsl:template match="dataFieldInDb">
  <dataFieldInDb>
    <xsl:call-template name="booleanField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataFieldInDb>
</xsl:template>

<xsl:template match="dataFieldState">
  <dataFieldState>
    <type>text</type>
    <label></label>
    <multiplicity>one</multiplicity>
    <valids>
      <valid>Private</valid>
      <valid>Updated</valid>
      <valid>SubmittedPrivate</valid>
      <valid>SubmittedUpdated</valid>
      <valid>Published</valid>
    </valids>
    <constraints>
      <required>true</required>
      <editable>false</editable>
    </constraints>
    <xsl:copy-of select="./value"/>
  </dataFieldState>
</xsl:template>

<xsl:template match="dataFieldLastExtracted">
  <dataFieldLastExtracted>
    <xsl:call-template name="dateField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataFieldLastExtracted>
</xsl:template>

<xsl:template match="dataFieldLastModified">
  <dataFieldLastModified>
    <xsl:call-template name="dateField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataFieldLastModified>
</xsl:template>

<xsl:template match="dataFieldLastPublished">
  <dataFieldLastPublished>
    <xsl:call-template name="dateField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataFieldLastPublished>
</xsl:template>

<xsl:template match="dataFieldMinValid">
  <dataFieldMinValid>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'Minimum Valid Value'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'-100.1'"/>
    </xsl:call-template>
  </dataFieldMinValid>
</xsl:template>

<xsl:template match="dataFieldMaxValid">
  <dataFieldMaxValid>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'Maximum Valid Value'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'1000.1'"/>
    </xsl:call-template>
  </dataFieldMaxValid>
</xsl:template>

<xsl:template match="dataFieldNominalMinValue">
  <dataFieldNominalMinValue>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'Nominal minimum value'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'0.5'"/>
    </xsl:call-template>
  </dataFieldNominalMinValue>
</xsl:template>

<xsl:template match="dataFieldNominalMaxValue">
  <dataFieldNominalMaxValue>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'Nominal maximum value'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'1.0'"/>
    </xsl:call-template>
  </dataFieldNominalMaxValue>
</xsl:template>

<xsl:template match="dataFieldValuesDistribution">
  <dataFieldValuesDistribution>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Data Values Distribution'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataFieldValuesDistribution>
</xsl:template>

<xsl:template match="dataFieldTimeIntvRepPos">
  <dataFieldTimeIntvRepPos>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Time Interval Representative Position'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataFieldTimeIntvRepPos>
</xsl:template>

<xsl:template match="dataFieldWavelengths">
  <dataFieldWavelengths>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'Wavelengths'"/>
      <xsl:with-param name="multiplicity" select="'many'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'550'"/>
    </xsl:call-template>
  </dataFieldWavelengths>
</xsl:template>

<xsl:template match="dataFieldWavelengthUnits">
  <dataFieldWavelengthUnits>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Wavelength Units'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'nm'"/>
    </xsl:call-template>
  </dataFieldWavelengthUnits>
</xsl:template>

<xsl:template match="dataFieldDepths">
  <dataFieldDepths>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'Depths'"/>
      <xsl:with-param name="multiplicity" select="'many'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'10-40'"/>
    </xsl:call-template>
  </dataFieldDepths>
</xsl:template>

<xsl:template match="dataFieldDepthUnits">
  <dataFieldDepthUnits>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Depth Units'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'cm'"/>
    </xsl:call-template>
  </dataFieldDepthUnits>
</xsl:template>

<xsl:template match="dataFieldZDimensionName">
  <dataFieldZDimensionName>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Z-dimension name (if any)'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'TempPrsLvls_A'"/>
    </xsl:call-template>
  </dataFieldZDimensionName>
</xsl:template>

<xsl:template match="dataFieldZDimensionType">
  <dataFieldZDimensionType>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Z-dimension type (if any)'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'pressure'"/>
    </xsl:call-template>
  </dataFieldZDimensionType>
</xsl:template>

<xsl:template match="dataFieldZDimensionUnits">
  <dataFieldZDimensionUnits>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Z-dimension units (if any)'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'hPa'"/>
    </xsl:call-template>
  </dataFieldZDimensionUnits>
</xsl:template>

<xsl:template match="dataFieldZDimensionValues">
  <dataFieldZDimensionValues>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Z-dimension values (space-separated, if any)'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'1000 500 100 50 30 10 5 1'"/>
    </xsl:call-template>
  </dataFieldZDimensionValues>
</xsl:template>

</xsl:stylesheet>
