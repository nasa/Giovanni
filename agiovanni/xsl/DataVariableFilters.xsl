<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/variable">
  
  
  <table class="dvTable">
    <xsl:for-each select="transform">
    <tr>
      <xsl:attribute name="name"><xsl:value-of select="../@name"/>:<xsl:value-of select="@value"/></xsl:attribute>
			<input type='hidden'>
		           <xsl:attribute name="name"><xsl:value-of select="../@name"/>_Filter</xsl:attribute>
		           <xsl:attribute name="value"><xsl:value-of select="@value"/></xsl:attribute>
			</input>
      <td class="dvFilterLabel">
	<xsl:choose>
	  <xsl:when test='@document!=""'>
	    <a>
		<xsl:attribute name="href"><xsl:value-of select="@document"/></xsl:attribute>
		<xsl:attribute name="target"><xsl:text>help</xsl:text></xsl:attribute>
		<xsl:attribute name="onclick">
			<xsl:text>window.open('</xsl:text>
			<xsl:value-of select="@document"/>
			<xsl:text>','help','scrollbars,resizeable,width=1000,height=500');</xsl:text>
		</xsl:attribute>
		<xsl:value-of select="@label"/>
	    </a>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="@label"/>:
	  </xsl:otherwise>
	</xsl:choose>
      </td>
      <!-- <td><xsl:value-of select="@value"/></td> -->
      <td class="dvFilterValue">
	<!--	<select>
		  <xsl:attribute name="name"><xsl:value-of select="../@name"/>_Filter</xsl:attribute>
		  <xsl:attribute name="id">
			<xsl:value-of select="../@name"/>+<xsl:value-of select="@value"/>
		  </xsl:attribute>
	-->
      		  <xsl:for-each select="option">
			<input type='radio' class='dvFilterInput'>
		                <xsl:attribute name="name"><xsl:value-of select="../../@name"/>+<xsl:value-of select="../@value"/></xsl:attribute>
		  		<xsl:attribute name="id">
					<xsl:value-of select="../../@name"/>+<xsl:value-of select="../@value"/>+<xsl:value-of select="@value"/>
			        </xsl:attribute>
		  		<!-- <xsl:attribute name="text">
					<xsl:value-of select="@label"/>
			        </xsl:attribute> -->
		  		<xsl:attribute name="value">
					<xsl:value-of select="@value"/>
			        </xsl:attribute>
				<!-- <xsl:if test='position()="1"'> -->
				<xsl:if test='@default="true"'>
				  <xsl:attribute name="checked">checked</xsl:attribute>
				</xsl:if>
			</input>
					<xsl:value-of select="@label"/><xsl:text>  </xsl:text>
      		</xsl:for-each>
		<!-- </select> -->
      </td>
    </tr>
    </xsl:for-each>
  </table>


</xsl:template>

</xsl:stylesheet>
