<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Giovanni Provenance</title>
        <style>
           table.lineage
           {
               font-family:sans-serif;
               border-collapse:collapse;
           }

           td.lineage 
           {
               padding:3px;
               vertical-align:top;
           }

           td.group_title
           {
               font-size: 110%;
               font-weight:bold;
               background-color: #5f9191;
               color:white;
               letter-spacing:1px;
               padding-left:5px;
               font-style:italic;
           }

           td.input_output_label
           {
               font-weight: bold;
               background-color: #d0e7e7;
               padding-left:5px;
           }

           td.input_output_column_label
           {
               min-width:5em;
               padding-left:5px;
           }
           td.input_output_column_value
           {
               padding-left: 10px;
           }

           td.step_message
           {
               font-weight:bold;
               font-style:italic;
               color:#993300;
               padding: 5px 3px; 10px 5px;
           }

           td.data_access_document
           {
               font-size: 120%;
               font-weight:bold;
               font-style:italic;
               color:#993300;
               padding: 5px 3px; 10px 5px;
           }

           .downloadCell
           {
               padding-left:8px;
               color:#993300;
               font-weight:bold;
           }
        </style>
      </head>
      <body>
        <xsl:apply-templates/>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="provenance">
    <table class="lineage">
      <tr>
        <td class="data_access_document" colspan="2">Giovanni now requires a login for data access.  Please read the helpful <a href="https://disc.gsfc.nasa.gov/data-access" target="_blank">Data Access How-To</a> document for more information.</td>
      </tr>
      <xsl:if test="./@ELAPSED_TIME">
        <tr>
          <td class="lineage" colspan="2">Total Elapsed Time: <xsl:value-of select="@ELAPSED_TIME"/> s</td>
        </tr>
      </xsl:if>
      <xsl:apply-templates/>
    </table>
  </xsl:template>
  <xsl:template name="InputOutput">
    <tr>
      <td class="lineage input_output_column_label">
        <xsl:value-of select="@NAME"/>
      </td>
      <td class="lineage input_output_column_value">
        <xsl:choose>
          <xsl:when test="@TYPE='URL'">
            <xsl:element name="a">
              <xsl:attribute name="target">_blank</xsl:attribute>
              <xsl:attribute name="href">
                <xsl:value-of select="text()"/>
              </xsl:attribute>
              <xsl:choose>
                <xsl:when test="@LABEL">
                  <xsl:value-of select="@LABEL"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="text()"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:element>
          </xsl:when>
          <xsl:when test="@TYPE='PARAMETER'">
            <!-- If the type is 'PARAMETER', copy text node content -->
            <xsl:value-of select="text()"/>
          </xsl:when>
          <xsl:otherwise>
                        Not available
                    </xsl:otherwise>
        </xsl:choose>
      </td>
    </tr>
  </xsl:template>
  <xsl:template match="group">
    <tr>
      <td colspan="2" class="lineage group_title">
        <xsl:choose>
          <xsl:when test="@name='workflow_queue_info'">
                      Waiting for System Resources
                  </xsl:when>
          <xsl:when test="@name='data_field_info'">
                      Catalog Query
                  </xsl:when>
          <xsl:when test="@name='data_group'">
                      Group Data by Class
                  </xsl:when>
          <xsl:when test="@name='data_class'">
                      Classify Data
                  </xsl:when>
          <xsl:when test="@name='data_search'">
                      Data File Search
                  </xsl:when>
          <xsl:when test="@name='data_fetch'">
                      Data File Staging
                  </xsl:when>
          <xsl:when test="@name='regrid'">
                      Data Regridding
                  </xsl:when>
          <xsl:when test="@name='algorithm+sTmAvSc'">
                      Time Averaged Scatter Plot
                  </xsl:when>
          <xsl:when test="@name='algorithm+sArAvTs'">
                      Area Averaged Time Series
                  </xsl:when>
          <xsl:when test="@name='algorithm+sTmAvMp'">
                      Time Averaged Map
                  </xsl:when>
          <xsl:when test="@name='algorithm+sCoMp'">
                      Correlation Map
                  </xsl:when>
          <xsl:when test="@name='algorithm+sStSc'">
                      Scatter Plot
                  </xsl:when>
          <xsl:when test="@name='algorithm+sVtPf'">
                      Vertical Profile
                  </xsl:when>
          <xsl:when test="@name='algorithm+sIaSc'">
                      Interactive Scatter Plot
                  </xsl:when>
          <xsl:when test="@name='algorithm+sMp'">
                      Interactive Map
                  </xsl:when>
          <xsl:when test="@name='algorithm+sMpAn'">
                      Animation
                  </xsl:when>
          <xsl:when test="@name='algorithm+sQuCl'">
                      Quasi Climatology Map
                  </xsl:when>
          <xsl:when test="@name='algorithm+sInTs'">
                      Seasonal Time Series
                  </xsl:when>
          <xsl:when test="@name='algorithm+sHvLn'">
                      Time-Longitude Hovmoller
                  </xsl:when>
          <xsl:when test="@name='algorithm+sHvLt'">
                      Time-Latitude Hovmoller
                  </xsl:when>
          <xsl:when test="@name='world+sCoMp'">
                      Longitude extension from -180 to 180 degrees
                  </xsl:when>
          <xsl:when test="@name='world+sMp'">
                      Longitude extension from -180 to 180 degrees
                  </xsl:when>
          <xsl:when test="@name='world+sMpAn'">
                      Longitude extension from -180 to 180 degrees
                  </xsl:when>
          <xsl:when test="@name='world+sQuCl'">
                      Longitude extension from -180 to 180 degrees
                  </xsl:when>
          <xsl:when test="@name='world+sHvLn'">
                      Longitude extension from -180 to 180 degrees
                      Time-Longitude Hovmoller
                  </xsl:when>
          <xsl:when test="@name='getData'">
                      Search for and retrieve data
                  </xsl:when>
          <xsl:when test="@name='biasCorrection'">
                      Correct bias
                  </xsl:when>
          <xsl:when test="@name='timeMatchup'">
                      Match up data by time
                  </xsl:when>
          <xsl:when test="@name='expand_BBox'">
                      Pad bounding box by a fixed number of degrees in all directions
                  </xsl:when>
          <xsl:when test="@name='expand_time'">
                      Pad time by a fixed number of minutes
                  </xsl:when>
          <xsl:when test="@name='as3_grid'">
                      Put data on a regular grid
                  </xsl:when>
          <xsl:when test="@name='shape_mask+sTmAvMp'">
                      Shape Subsetting
                  </xsl:when>
          <xsl:when test="@name='shape_mask+sArAvTs'">
                      Shape Masking
                  </xsl:when>
          <xsl:when test="@name='shape_mask+sHiGm'">
                      Shape Subsetting
                  </xsl:when>
          <xsl:when test="@name='shape_mask+sInTs'">
                      Shape Subsetting
                  </xsl:when>
          <xsl:when test="starts-with(@name, 'postprocess')">Post-Processing</xsl:when>
          <xsl:when test="@name=&quot;result+sCrLt&quot;">Cross Section, Latitude-Pressure</xsl:when>
          <xsl:when test="@name=&quot;result+sCrLn&quot;">Cross Section, Longitude-Pressure</xsl:when>
          <xsl:when test="@name=&quot;result+sCrTm&quot;">Cross Section, Time-Pressure</xsl:when>
          <xsl:when test="@name=&quot;result+sHvLt&quot;">Hovmoller, Longitude-Averaged</xsl:when>
          <xsl:when test="@name=&quot;result+sHvLn&quot;">Hovmoller, Latitude-Averaged</xsl:when>
          <xsl:when test="@name=&quot;result+sVtPf&quot;">Vertical Profile</xsl:when>
          <xsl:when test="@name=&quot;result+sZnMn&quot;">Zonal Mean</xsl:when>
          <xsl:when test="@name=&quot;result+sMpAn&quot;">Animation</xsl:when>
          <xsl:when test="@name=&quot;result+sDiArAvTs&quot;">Time Series, Area-Averaged Differences</xsl:when>
          <xsl:when test="@name=&quot;result+sArAvSc&quot;">Scatter, Area Averaged (Static)</xsl:when>
          <xsl:when test="@name=&quot;result+sArAvTs&quot;">Time Series, Area-Averaged</xsl:when>
          <xsl:when test="@name=&quot;result+sIaSc&quot;">Scatter (Interactive)</xsl:when>
          <xsl:when test="@name=&quot;result+sStSc&quot;">Scatter (Static)</xsl:when>
          <xsl:when test="@name=&quot;result+sDiTmAvMp&quot;">Map, Difference of Time Averaged</xsl:when>
          <xsl:when test="@name=&quot;result+sAcMp&quot;">Map, Accumulated</xsl:when>
          <xsl:when test="@name=&quot;result+sTmAvMp&quot;">Time Averaged Map</xsl:when>
          <xsl:when test="@name=&quot;result+sTmAvOvMp&quot;">Time Averaged Overlay Map</xsl:when>
          <xsl:when test="@name=&quot;result+sTmAvSc&quot;">Scatter, Time-Averaged (Interactive)</xsl:when>
          <xsl:when test="@name=&quot;result+sQuCl&quot;">Monthly and Seasonal Averages</xsl:when>
          <xsl:when test="@name=&quot;result+sHiGm&quot;">Histogram</xsl:when>
          <xsl:when test="@name=&quot;result+sInTs&quot;">Time Series, Seasonal</xsl:when>
          <xsl:otherwise>
                      Anonymous Step 
                  </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="./@ELAPSED_TIME"> (Time taken: <xsl:value-of select="@ELAPSED_TIME"/> s)</xsl:if>
      </td>
      <xsl:if test=".//message">
        <tr>
          <td class="lineage input_output_label" colspan="2">Messages</td>
        </tr>
        <tr>
          <td colspan="2" class="lineage input_output_column_value">
            <xsl:for-each select="./step/messages/message">
              <xsl:value-of select="text()"/>
              <br/>
            </xsl:for-each>
          </td>
        </tr>
      </xsl:if>
      <xsl:if test=".//output">
        <tr>
          <td class="lineage input_output_label" colspan="2">Output</td>
        </tr>
      </xsl:if>
      <xsl:for-each select="./step/outputs/output[position() &lt;= $maxUrlCount]">
        <xsl:call-template name="InputOutput"/>
      </xsl:for-each>
      <tr>
        <td colspan="2" class="step_message">
          <xsl:if test="count(./step/outputs/output[@TYPE='URL']) &gt; $maxUrlCount">
                  Too many URLs to display. 
              </xsl:if>

          <xsl:if test="count(./step/outputs/output[@NAME='classified file']) &lt; 1 and @name!='workflow_queue_info'">
            <xsl:element name="a"><xsl:attribute name="target">_blank</xsl:attribute><xsl:attribute name="href"><xsl:value-of select="$downloadScript"/>?step=<xsl:value-of select="@name"/>&amp;session=<xsl:value-of select="$session"/>&amp;resultset=<xsl:value-of select="$resultset"/>&amp;result=<xsl:value-of select="$result"/></xsl:attribute>
                  Download list of all URLs in step
                </xsl:element>
          </xsl:if>
        </td>
      </tr>
      <xsl:if test="count(./step/outputs/output[@TYPE='PARAMETER']) &gt; $maxUrlCount and count(./step/outputs/output[@NAME='classified file']) &gt; 1">
        <tr>
          <td colspan="2" class="step_message">
              Too many outputs to display. 
              <xsl:element name="a"><xsl:attribute name="target">_blank</xsl:attribute><xsl:attribute name="href"><xsl:value-of select="$downloadScript"/>?step=<xsl:value-of select="@name"/>&amp;session=<xsl:value-of select="$session"/>&amp;resultset=<xsl:value-of select="$resultset"/>&amp;result=<xsl:value-of select="$result"/></xsl:attribute>
                Download list of all outputs in step
              </xsl:element>
          </td>
        </tr>
      </xsl:if>
    </tr>
  </xsl:template>
  <!-- Old style lineage -->
  <xsl:template match="Lineage">
    <table border="1">
      <xsl:apply-templates/>
    </table>
  </xsl:template>
  <xsl:template match="Step">
    <xsl:if test="count(input)">
      <tr style="background:lightblue; color:black">
        <th>Step <xsl:number format="1."/></th>
        <th>
          <xsl:value-of select="@name"/>
          <xsl:if test="./@endtime">( <xsl:value-of select="@endtime"/></xsl:if>
        </th>
      </tr>
      <xsl:for-each select="input">
        <tr>
          <xsl:if test="@name">
            <td>
              <xsl:value-of select="@name"/>
            </td>
            <td>
              <xsl:value-of select="text()"/>
            </td>
          </xsl:if>
          <xsl:if test="@type='URL'">
            <td>URL</td>
            <td>
              <xsl:element name="a">
                <xsl:attribute name="target">_blank</xsl:attribute>
                <xsl:attribute name="href">
                  <xsl:value-of select="text()"/>
                </xsl:attribute>
                <xsl:value-of select="text()"/>
              </xsl:element>
            </td>
          </xsl:if>
        </tr>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>
  <!-- New style lineage -->
  <xsl:template match="lineage">
    <xsl:if test="./@ELAPSED_TIME">Total Elapsed Time: <xsl:value-of select="@ELAPSED_TIME"/> s</xsl:if>
    <table border="1">
      <xsl:apply-templates/>
    </table>
  </xsl:template>
  <xsl:template match="step">
    <xsl:if test="count(.//input)">
      <tr style="background:lightblue; color:black">
        <th>Step <xsl:number format="1."/></th>
        <th>
          <xsl:choose>
            <xsl:when test="@LABEL">
              <xsl:value-of select="@LABEL"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="@NAME"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="./@ENDTIME"> (completed at <xsl:value-of select="substring(@ENDTIME, 12,9)"/>)</xsl:if>
          <xsl:if test="./@ELAPSED_TIME"> (took <xsl:value-of select="@ELAPSED_TIME"/> seconds)</xsl:if>
        </th>
      </tr>
      <xsl:if test=".//input">
        <tr>
          <th colspan="2">Input</th>
        </tr>
      </xsl:if>
      <xsl:for-each select=".//input">
        <tr>
          <td>
            <xsl:choose>
              <xsl:when test="@LABEL">
                <xsl:value-of select="@LABEL"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@NAME"/>
              </xsl:otherwise>
            </xsl:choose>
          </td>
          <xsl:choose>
            <xsl:when test="@TYPE='URL'">
              <td>
                <xsl:element name="a">
                  <xsl:attribute name="target">_blank</xsl:attribute>
                  <xsl:attribute name="href">
                    <xsl:value-of select="text()"/>
                  </xsl:attribute>
                  <xsl:value-of select="text()"/>
                </xsl:element>
              </td>
            </xsl:when>
            <xsl:when test="@TYPE='PARAMETER'">
              <!-- If the type is 'PARAMETER', copy text node content -->
              <td>
                <xsl:value-of select="text()"/>
              </td>
            </xsl:when>
            <xsl:otherwise>
              <td>Not available</td>
            </xsl:otherwise>
          </xsl:choose>
        </tr>
      </xsl:for-each>
      <xsl:if test=".//output">
        <tr>
          <th colspan="2">Output</th>
        </tr>
      </xsl:if>
      <xsl:for-each select=".//output">
        <tr>
          <td>
            <xsl:choose>
              <xsl:when test="@LABEL">
                <xsl:value-of select="@LABEL"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@NAME"/>
              </xsl:otherwise>
            </xsl:choose>
          </td>
          <xsl:choose>
            <xsl:when test="@TYPE='URL'">
              <td>
                <xsl:element name="a">
                  <xsl:attribute name="target">_blank</xsl:attribute>
                  <xsl:attribute name="href">
                    <xsl:value-of select="text()"/>
                  </xsl:attribute>
                  <xsl:value-of select="text()"/>
                </xsl:element>
              </td>
            </xsl:when>
            <xsl:when test="@TYPE='PARAMETER'">
              <!-- If the type is 'PARAMETER', copy text node content -->
              <td>
                <xsl:value-of select="text()"/>
              </td>
            </xsl:when>
            <xsl:otherwise>
              <td>Not available</td>
            </xsl:otherwise>
          </xsl:choose>
        </tr>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>


