<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
xmlns:java="http://xml.apache.org/xslt/java" exclude-result-prefixes="java">

<xsl:output method="xml" version="1.0" indent="yes" />

<xsl:template match="dataProduct">
  <dataProduct>
    <xsl:apply-templates select="./dataProductId" />
    <dataProductIdentifiers>
      <type>container</type>
      <label>Data Set</label>
      <multiplicity>one</multiplicity>
      <value>
	<xsl:apply-templates select="./dataProductDataSetId" />
	<xsl:apply-templates select="./dataProductGcmdEntryId" />
	<xsl:apply-templates select="./dataProductShortName" />
	<xsl:apply-templates select="./dataProductVersion" />
	<xsl:apply-templates select="./dataProductLongName" />
      </value>
    </dataProductIdentifiers>
    <xsl:apply-templates select="./dataProductDescriptionUrl" />
    <xsl:apply-templates select="./dataProductProcessingLevel" />
    <xsl:apply-templates select="./dataProductDataCenter" />
    <dataProductPlatform>
      <type>container</type>
      <label>Platform</label>
      <multiplicity>one</multiplicity>
      <value>
	<xsl:apply-templates select="./dataProductPlatformShortName" />
	<xsl:apply-templates select="./dataProductPlatformLongName" />
      </value>
    </dataProductPlatform>
    <dataProductInstrument>
      <type>container</type>
      <label>Instrument</label>
      <multiplicity>one</multiplicity>
      <value>
	<xsl:apply-templates select="./dataProductInstrumentShortName" />
	<xsl:apply-templates select="./dataProductInstrumentLongName" />
      </value>
    </dataProductInstrument>
    <xsl:apply-templates select="./dataProductPlatformInstrument" />
    <dataProductSpatialResolution>
      <type>container</type>
      <label>Spatial Resolution</label>
      <multiplicity>one</multiplicity>
      <value>
	<xsl:apply-templates select="./dataProductSpatialResolutionLatitude" />
	<xsl:apply-templates select="./dataProductSpatialResolutionLongitude" />
	<xsl:apply-templates select="./dataProductSpatialResolutionUnits" />
      </value>
    </dataProductSpatialResolution>
    <dataProductSpatialCoverage>
      <type>container</type>
      <label>Spatial Coverage</label>
      <multiplicity>one</multiplicity>
      <value>
	<xsl:apply-templates select="./dataProductWest" />
	<xsl:apply-templates select="./dataProductNorth" />
	<xsl:apply-templates select="./dataProductEast" />
	<xsl:apply-templates select="./dataProductSouth" />
      </value>
    </dataProductSpatialCoverage>
    <dataProductTemporalCoverage>
      <type>container</type>
      <label>Temporal Coverage</label>
      <multiplicity>one</multiplicity>
      <value>
	<xsl:apply-templates select="./dataProductBeginDateTime" />
	<xsl:apply-templates select="./dataProductEndDateTime" />
	<xsl:apply-templates select="./dataProductEndDateTimeLocked" />
	<xsl:apply-templates select="./dataProductTimeFrequency" />
	<xsl:apply-templates select="./dataProductTimeInterval" />
	<xsl:apply-templates select="./dataProductStartTimeOffset" />
	<xsl:apply-templates select="./dataProductEndTimeOffset" />
      </value>
    </dataProductTemporalCoverage>
    <xsl:apply-templates select="./dataProductSearchIntervalDays" />
    <xsl:apply-templates select="./dataProductOsddUrl" />
    <xsl:apply-templates select="./dataProductSampleGranuleUrl" />
    <xsl:apply-templates select="./dataProductOpendapUrl" />
    <xsl:apply-templates select="./dataProductResponseFormat" />
    <xsl:apply-templates select="./dataProductSpecialFeatures" />
    <xsl:apply-templates select="./dataProductInternal" />
    <xsl:apply-templates select="./dataProductDataFieldIds" />
    <xsl:apply-templates select="./dataProductCanAddNewFields" />
    <xsl:apply-templates select="./dataProductGcmdLastRevisionDate" />
    <xsl:apply-templates select="./dataProductLastModified" />
  </dataProduct>
</xsl:template>

<xsl:template name="wordTextField">
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
  <xsl:param name="multiplicity"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="maxlength"/>
  <xsl:param name="example"/>
  <type>text</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity><xsl:value-of select="$multiplicity"/></multiplicity>
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
  <xsl:param name="maxlength"/>
  <xsl:param name="example"/>
  <type>text</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <regex>[a-zA-Z0-9_.-]+$</regex>
    <validationText>The value must consist only of letters, digits, underscores, dots, and hyphens.</validationText>
    <xsl:if test="$maxlength">
      <maxlength><xsl:value-of select="$maxlength"/></maxlength>
    </xsl:if>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="wordWithSpaceDotHyphenTextField">
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
    <regex>[ a-zA-Z0-9_.-]+$</regex>
    <validationText>The value must consist only of letters, digits, underscores, dots, hyphens, and spaces.</validationText>
    <xsl:if test="$maxlength">
      <maxlength><xsl:value-of select="$maxlength"/></maxlength>
    </xsl:if>
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
  <xsl:param name="maxlength"/>
  <xsl:param name="example"/>
  <type><xsl:value-of select="$type"/></type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity><xsl:value-of select="$multiplicity"/></multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <xsl:if test="$maxlength">
      <maxlength><xsl:value-of select="$maxlength"/></maxlength>
    </xsl:if>
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
  <xsl:param name="defaultValue" />
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
  <xsl:choose>
    <xsl:when test="$node/value/text() != ''">
      <xsl:copy-of select="$node/value"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="value">
	<xsl:if test="$defaultValue">
	  <xsl:value-of select="$defaultValue" />
	</xsl:if>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>
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

<xsl:template name="cgiUrlField">
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
    <regex>^(?:http|https|ftp)://[\w.-]+(?::\d+)?/[-\w\d/.#~\?&amp;=]+$</regex>
    <validationText>The value must have the form of a URL.</validationText>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="nameField">
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
    <regex>[a-zA-Z0-9 _.,)(&amp;/-]+$</regex>
    <validationText>The value must consist only of letters, digits, spaces, underscores, dots, commas, parentheses, ampersands, slashes, and hyphens.</validationText>
    <xsl:if test="$maxlength">
      <maxlength><xsl:value-of select="$maxlength"/></maxlength>
    </xsl:if>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="wordWithSpaceDotSlashHyphenTextListField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="example"/>
  <type>list</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>many</multiplicity>
  <valids/>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <regex>[a-zA-Z0-9 _./-]+$</regex>
    <validationText>The value must consist only of letters, digits, spaces, underscores, dots, slashes, and hyphens.</validationText>
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
  <xsl:param name="example"/>
  <type>boolean</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
    <!--
    <regex>^true$|^false$</regex>
    <validationText>The value must be either 'true' or 'false'</validationText>
    -->
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template name="dateField">
  <xsl:param name="node"/>
  <xsl:param name="label"/>
  <xsl:param name="multiplicity"/>
  <xsl:param name="required"/>
  <xsl:param name="editable"/>
  <xsl:param name="example"/>
  <type>datetime</type>
  <label><xsl:value-of select="$label"/></label>
  <multiplicity>one</multiplicity>
  <constraints>
    <required><xsl:value-of select="$required"/></required>
    <editable><xsl:value-of select="$editable"/></editable>
  </constraints>
  <xsl:if test="$example">
    <example><xsl:value-of select="$example"/></example>
  </xsl:if>
  <xsl:copy-of select="$node/value"/>
</xsl:template>

<xsl:template match="dataProductId">
  <dataProductId>
    <xsl:call-template name="wordWithDotHyphenTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
   </xsl:call-template>
  </dataProductId>
</xsl:template>

<xsl:template match="dataProductDataSetId">
  <dataProductDataSetId>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
      <xsl:with-param name="example" select="'Aqua AIRS Level 3 Monthly Standard Physical Retrieval (AIRS+AMSU) V006'"/>
   </xsl:call-template>
  </dataProductDataSetId>
</xsl:template>

<xsl:template match="dataProductGcmdEntryId">
  <dataProductGcmdEntryId>
    <xsl:call-template name="wordWithDotHyphenTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'GCMD Entry ID or Unique Id'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
      <xsl:with-param name="maxlength" select="'80'"/>
      <xsl:with-param name="example" select="'GES_DISC_AIRX3STM_V006'"/>
   </xsl:call-template>
  </dataProductGcmdEntryId>
</xsl:template>

<xsl:template match="dataProductShortName">
  <dataProductShortName>
    <xsl:call-template name="wordWithSpaceDotHyphenTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Short Name'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
      <xsl:with-param name="example" select="'AIRX3STM'"/>
   </xsl:call-template>
  </dataProductShortName>
</xsl:template>

<xsl:template match="dataProductVersion">
  <dataProductVersion>
    <xsl:call-template name="wordWithDotHyphenTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Version'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
      <xsl:with-param name="example" select="'006'"/>
   </xsl:call-template>
  </dataProductVersion>
</xsl:template>

<xsl:template match="dataProductLongName">
  <dataProductLongName>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Long Name'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="maxlength" select="'220'"/>
      <xsl:with-param name="example" select="'Aqua AIRS Level 3 Monthly Standard Physical Retrieval (AIRS+AMSU)'"/>
   </xsl:call-template>
  </dataProductLongName>
</xsl:template>

<xsl:template match="dataProductDescriptionUrl">
  <dataProductDescriptionUrl>
    <xsl:call-template name="urlField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Description URL'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'http://gcmd.gsfc.nasa.gov/getdif.htm?MOD08_D3'"/>
    </xsl:call-template>
  </dataProductDescriptionUrl>
</xsl:template>

<xsl:template match="dataProductProcessingLevel">
  <dataProductProcessingLevel>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Processing Level'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataProductProcessingLevel>
</xsl:template>

<xsl:template match="dataProductDataCenter">
  <dataProductDataCenter>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="label" select="'Data Center'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'NASA/GSFC/SED/ESD/GCDC/GESDISC'"/>
    </xsl:call-template>
  </dataProductDataCenter>
</xsl:template>

<xsl:template match="dataProductPlatformShortName">
  <dataProductPlatformShortName>
    <xsl:call-template name="nameField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Short Name'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'Aqua'"/>
    </xsl:call-template>
  </dataProductPlatformShortName>
</xsl:template>

<xsl:template match="dataProductPlatformLongName">
  <dataProductPlatformLongName>
    <xsl:call-template name="nameField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Long Name'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'Earth Observing System, AQUA'"/>
    </xsl:call-template>
  </dataProductPlatformLongName>
</xsl:template>

<xsl:template match="dataProductInstrumentShortName">
  <dataProductInstrumentShortName>
    <xsl:call-template name="nameField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Short Name'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'MODIS'"/>
    </xsl:call-template>
  </dataProductInstrumentShortName>
</xsl:template>

<xsl:template match="dataProductInstrumentLongName">
  <dataProductInstrumentLongName>
    <xsl:call-template name="nameField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Long Name'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'Moderate-Resolution Imaging Spectroradiometer'"/>
    </xsl:call-template>
  </dataProductInstrumentLongName>
</xsl:template>

<xsl:template match="dataProductPlatformInstrument">
  <dataProductPlatformInstrument>
    <xsl:call-template name="wordWithSpaceDotSlashHyphenTextListField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Source'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'MODIS-Terra'"/>
    </xsl:call-template>
  </dataProductPlatformInstrument>
</xsl:template>

<xsl:template match="dataProductSpatialResolutionLatitude">
  <dataProductSpatialResolutionLatitude>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'Latitude'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'0.5'"/>
    </xsl:call-template>
  </dataProductSpatialResolutionLatitude>
</xsl:template>

<xsl:template match="dataProductSpatialResolutionLongitude">
  <dataProductSpatialResolutionLongitude>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'Longitude'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'1.0'"/>
    </xsl:call-template>
  </dataProductSpatialResolutionLongitude>
</xsl:template>

<xsl:template match="dataProductSpatialResolutionUnits">
  <dataProductSpatialResolutionUnits>
    <xsl:call-template name="basicValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'list'"/>
      <xsl:with-param name="label" select="'Units'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'deg.'"/>
    </xsl:call-template>
  </dataProductSpatialResolutionUnits>
</xsl:template>

<xsl:template match="dataProductWest">
  <dataProductWest>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'West'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'-180.0'"/>
    </xsl:call-template>
  </dataProductWest>
</xsl:template>

<xsl:template match="dataProductNorth">
  <dataProductNorth>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'North'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'90.0'"/>
    </xsl:call-template>
  </dataProductNorth>
</xsl:template>

<xsl:template match="dataProductEast">
  <dataProductEast>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'East'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'180.0'"/>
    </xsl:call-template>
  </dataProductEast>
</xsl:template>

<xsl:template match="dataProductSouth">
  <dataProductSouth>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'South'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'-90.0'"/>
    </xsl:call-template>
  </dataProductSouth>
</xsl:template>

<xsl:template match="dataProductBeginDateTime">
  <dataProductBeginDateTime>
    <xsl:call-template name="dateField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Start Date/Time'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'2002-08-30T00:00:00Z'"/>
    </xsl:call-template>
  </dataProductBeginDateTime>
</xsl:template>

<xsl:template match="dataProductEndDateTime">
  <dataProductEndDateTime>
    <xsl:call-template name="dateField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'End Date/Time'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'2011-06-29T22:29:59Z'"/>
    </xsl:call-template>
  </dataProductEndDateTime>
</xsl:template>

<xsl:template match="dataProductEndDateTimeLocked">
  <dataProductEndDateTimeLocked>
    <xsl:call-template name="booleanField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'true'"/>
    </xsl:call-template>
  </dataProductEndDateTimeLocked>
</xsl:template>

<xsl:template match="dataProductTimeFrequency">
  <dataProductTimeFrequency>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Frequency'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataProductTimeFrequency>
</xsl:template>

<xsl:template match="dataProductTimeInterval">
  <dataProductTimeInterval>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Interval'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
    </xsl:call-template>
  </dataProductTimeInterval>
</xsl:template>

<xsl:template match="dataProductStartTimeOffset">
  <dataProductStartTimeOffset>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'Start time offset (seconds)'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'1'"/>
    </xsl:call-template>
  </dataProductStartTimeOffset>
</xsl:template>

<xsl:template match="dataProductEndTimeOffset">
  <dataProductEndTimeOffset>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'End time offset (seconds)'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'0'"/>
    </xsl:call-template>
  </dataProductEndTimeOffset>
</xsl:template>

<xsl:template match="dataProductSearchIntervalDays">
  <dataProductSearchIntervalDays>
    <xsl:call-template name="basicNoValidsField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'number'"/>
      <xsl:with-param name="label" select="'Duration of search intervals (in days)'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="''"/>
    </xsl:call-template>
  </dataProductSearchIntervalDays>
</xsl:template>

<xsl:template match="dataProductOsddUrl">
  <dataProductOsddUrl>
    <xsl:call-template name="cgiUrlField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'OpenSearch Descriptor Document for granules URL'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'https://cmr.earthdata.nasa.gov/opensearch/granules/descriptor_document.xml?clientId=giovanni&amp;shortName=AIRX3STD&amp;versionId=006&amp;dataCenter=GSFCS4PA'"/>
    </xsl:call-template>
  </dataProductOsddUrl>
</xsl:template>

<xsl:template match="dataProductSampleGranuleUrl">
  <dataProductSampleGranuleUrl>
    <xsl:call-template name="cgiUrlField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Sample OpenSearch data granule URL'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'ftp://acdisc.gsfc.nasa.gov/data/s4pa/Aqua_AIRS_Level3/AIRX3STM.006/2002/AIRS.2002.09.01.L3.RetStd030.v6.0.9.0.G13208054216.hdf'"/>
    </xsl:call-template>
  </dataProductSampleGranuleUrl>
</xsl:template>

<xsl:template match="dataProductOpendapUrl">
  <dataProductOpendapUrl>
    <xsl:call-template name="urlField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'(corresponding) Sample OPeNDAP granule URL'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'http://acdisc.gsfc.nasa.gov/opendap/Aqua_AIRS_Level3/AIRX3STM.006/2002/AIRS.2002.09.01.L3.RetStd030.v6.0.9.0.G13208054216.hdf.html'"/>
    </xsl:call-template>
  </dataProductOpendapUrl>
</xsl:template>

<xsl:template match="dataProductResponseFormat">
  <dataProductResponseFormat>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Access Format'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="defaultValue" select="'netCDF'"/>
    </xsl:call-template>
  </dataProductResponseFormat>
</xsl:template>

<xsl:template match="dataProductSpecialFeatures">
  <dataProductSpecialFeatures>
    <xsl:call-template name="listField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Special Features'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'true'"/>
      <xsl:with-param name="example" select="'climatology'"/>
    </xsl:call-template>
  </dataProductSpecialFeatures>
</xsl:template>

<xsl:template match="dataProductInternal">
  <dataProductInternal>
    <xsl:call-template name="booleanField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'true'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataProductInternal>
</xsl:template>

<xsl:template match="dataProductDataFieldIds">
  <dataProductDataFieldIds>
    <xsl:call-template name="wordWithHyphenTextField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="type" select="'text'"/>
      <xsl:with-param name="multiplicity" select="'many'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataProductDataFieldIds>
</xsl:template>

<xsl:template match="dataProductCanAddNewFields">
  <dataProductCanAddNewFields>
    <xsl:call-template name="booleanField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataProductCanAddNewFields>
</xsl:template>

<xsl:template match="dataProductGcmdLastRevisionDate">
  <dataProductGcmdLastRevisionDate>
    <xsl:call-template name="dateField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataProductGcmdLastRevisionDate>
</xsl:template>

<xsl:template match="dataProductLastModified">
  <dataProductLastModified>
    <xsl:call-template name="dateField">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="label" select="'Last modification date'"/>
      <xsl:with-param name="multiplicity" select="'one'"/>
      <xsl:with-param name="required" select="'false'"/>
      <xsl:with-param name="editable" select="'false'"/>
    </xsl:call-template>
  </dataProductLastModified>
</xsl:template>

</xsl:stylesheet>
