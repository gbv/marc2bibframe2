<?xml version='1.0'?>
<xsl:stylesheet version="1.0"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:marc="http://www.loc.gov/MARC21/slim"
                xmlns:bf="http://id.loc.gov/ontologies/bibframe/"
                xmlns:bflc="http://id.loc.gov/ontologies/bflc/"
                xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="xsl marc">

  <!-- Utility templates -->

  <!--
      Determine the xml:lang code from $6
  -->

  <xsl:template match="marc:datafield" mode="xmllang">
    <xsl:if test="marc:subfield[@code='6'] and ../marc:controlfield[@tag='008']">
      <xsl:variable name="vLang008"><xsl:value-of select="substring(../marc:controlfield[@tag='008'],36,3)"/></xsl:variable>
      <xsl:variable name="vScript6"><xsl:value-of select="substring-after(marc:subfield[@code='6'],'/')"/></xsl:variable>
      <xsl:variable name="vScript6simple">
        <xsl:choose>
          <xsl:when test="contains($vScript6,'/')"><xsl:value-of select="substring-before($vScript6,'/')"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="$vScript6"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="vLang"><xsl:value-of select="$languageMap/xml-langs/language/iso6392[text()=$vLang008]/parent::*/@xmllang"/></xsl:variable>
      <xsl:variable name="vScript">
        <xsl:choose>
          <xsl:when test="$vScript6simple='(3'">arab</xsl:when>
          <xsl:when test="$vScript6simple='(B'">latn</xsl:when>
          <xsl:when test="$vScript6simple='$1' and $vLang008='kor'">hang</xsl:when>
          <xsl:when test="$vScript6simple='$1' and $vLang008='chi'">hani</xsl:when>
          <xsl:when test="$vScript6simple='$1' and $vLang008='jpn'">jpan</xsl:when>
          <xsl:when test="$vScript6simple='(N'">cyrl</xsl:when>
          <xsl:when test="$vScript6simple='(S'">grek</xsl:when>
          <xsl:when test="$vScript6simple='(2'">hebr</xsl:when>
          <xsl:when test="string-length($vScript6simple)=4 and string-length(translate($vScript6simple,concat($upper,$lower),''))=0">
            <xsl:value-of select="$vScript6simple"/>
          </xsl:when>
          <xsl:when test="string-length($vScript6simple)=3 and string-length(translate($vScript6simple,'0123456789',''))=0">
            <xsl:value-of select="$scriptMap/xml-scripts/script[@num=$vScript6simple]/@code"/>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>
      <xsl:if test="$vLang != '' and $vScript != ''"><xsl:value-of select="concat($vLang,'-',$vScript)"/></xsl:if>
    </xsl:if>
  </xsl:template>
        
  <!--
      rudimentary LCC validation
      returns "true" if valid, "" if not valid
  -->
  <xsl:template name="validateLCC">
    <xsl:param name="pCall"/>
    <xsl:variable name="vAlpha">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
    <xsl:variable name="vNumber">0123456789</xsl:variable>
    <xsl:if test="string-length(translate(substring($pCall,1,1),$vAlpha,''))=0">
      <xsl:choose>
        <xsl:when test="string-length(translate(substring($pCall,2,1),$vAlpha,''))=0">
          <xsl:choose>
            <xsl:when test="string-length(translate(substring($pCall,3,1),$vAlpha,''))=0">
              <xsl:if test="string-length(translate(substring($pCall,4,1),$vNumber,''))=0">true</xsl:if>
            </xsl:when>
            <xsl:when test="string-length(translate(substring($pCall,3,1),$vNumber,''))=0">true</xsl:when>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="string-length(translate(substring($pCall,2,1),$vNumber,''))=0">true</xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!--
      Process 7 punctuation handling
  -->
  <xsl:template name="tChopPunct">
    <xsl:param name="pString"/>
    <xsl:param name="pEndPunct" select="'.:;,/='"/>
    <xsl:param name="pTermPunct" select="'.?!'"/>
    <xsl:param name="pLeadPunct" select="';='"/>
    <xsl:param name="pForceTerm" select="false()"/>
    <xsl:param name="pChopParens" select="false()"/>
    <xsl:variable name="vNormString" select="normalize-space($pString)"/>
    <xsl:variable name="vLength" select="string-length($vNormString)"/>
    <xsl:choose>
      
      <!-- no processing needed for empty string -->
      <xsl:when test="not($vNormString) or $vLength=0"/>

      <!-- remove enclosing parens when pChopParens is true -->
      <xsl:when test="substring($vNormString,1,1) = '(' and $pChopParens">
        <xsl:variable name="vCloseIndex">
          <xsl:call-template name="tLastIndex">
            <xsl:with-param name="pString" select="$vNormString"/>
            <xsl:with-param name="pSearch" select="')'"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$vCloseIndex &gt; 2">
            <xsl:call-template name="tChopPunct">
              <xsl:with-param name="pString" select="concat(substring($vNormString,2,$vCloseIndex - 2),substring($vNormString,$vCloseIndex+1))"/>
              <xsl:with-param name="pEndPunct" select="$pEndPunct"/>
              <xsl:with-param name="pLeadPunct" select="$pLeadPunct"/>
              <xsl:with-param name="pTermPunct" select="$pTermPunct"/>
              <xsl:with-param name="pForceTerm" select="$pForceTerm"/>
              <xsl:with-param name="pChopParens" select="$pChopParens"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="tChopPunct">
              <xsl:with-param name="pString" select="substring($vNormString,2)"/>
              <xsl:with-param name="pEndPunct" select="$pEndPunct"/>
              <xsl:with-param name="pLeadPunct" select="$pLeadPunct"/>
              <xsl:with-param name="pTermPunct" select="$pTermPunct"/>
              <xsl:with-param name="pForceTerm" select="$pForceTerm"/>
              <xsl:with-param name="pChopParens" select="$pChopParens"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- remove leading punctuation for combined works, parallel titles -->
      <xsl:when test="contains($pLeadPunct,substring($vNormString,1,1))">
        <xsl:call-template name="tChopPunct">
          <xsl:with-param name="pString" select="substring($vNormString,2)"/>
          <xsl:with-param name="pEndPunct" select="$pEndPunct"/>
          <xsl:with-param name="pLeadPunct" select="$pLeadPunct"/>
          <xsl:with-param name="pTermPunct" select="$pTermPunct"/>
          <xsl:with-param name="pForceTerm" select="$pForceTerm"/>
          <xsl:with-param name="pChopParens" select="$pChopParens"/>
        </xsl:call-template>
      </xsl:when>
      
      <!-- remove end enclosing punctuation if start character is not in string -->
      <xsl:when test="substring($vNormString,$vLength,1)=')' and not(contains($vNormString,'('))">
        <xsl:call-template name="tChopPunct">
          <xsl:with-param name="pString" select="substring($vNormString,1,$vLength - 1)"/>
          <xsl:with-param name="pEndPunct" select="$pEndPunct"/>
          <xsl:with-param name="pLeadPunct" select="$pLeadPunct"/>
          <xsl:with-param name="pTermPunct" select="$pTermPunct"/>
          <xsl:with-param name="pForceTerm" select="$pForceTerm"/>
          <xsl:with-param name="pChopParens" select="$pChopParens"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="substring($vNormString,$vLength,1)='}}' and not(contains($vNormString,'{{'))">
        <xsl:call-template name="tChopPunct">
          <xsl:with-param name="pString" select="substring($vNormString,1,$vLength - 1)"/>
          <xsl:with-param name="pEndPunct" select="$pEndPunct"/>
          <xsl:with-param name="pLeadPunct" select="$pLeadPunct"/>
          <xsl:with-param name="pTermPunct" select="$pTermPunct"/>
          <xsl:with-param name="pForceTerm" select="$pForceTerm"/>
          <xsl:with-param name="pChopParens" select="$pChopParens"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="substring($vNormString,$vLength,1)='&quot;' and not(contains(substring($vNormString,1,$vLength - 1),'&quot;'))">
        <xsl:call-template name="tChopPunct">
          <xsl:with-param name="pString" select="substring($vNormString,1,$vLength - 1)"/>
          <xsl:with-param name="pEndPunct" select="$pEndPunct"/>
          <xsl:with-param name="pLeadPunct" select="$pLeadPunct"/>
          <xsl:with-param name="pTermPunct" select="$pTermPunct"/>
          <xsl:with-param name="pForceTerm" select="$pForceTerm"/>
          <xsl:with-param name="pChopParens" select="$pChopParens"/>
        </xsl:call-template>
      </xsl:when>
      
      <!-- remove lead enclosing punctuation if end character is not in string -->
      <xsl:when test="substring($vNormString,1,1)='(' and not(contains($vNormString,')'))">
        <xsl:call-template name="tChopPunct">
          <xsl:with-param name="pString" select="substring($vNormString,2)"/>
          <xsl:with-param name="pEndPunct" select="$pEndPunct"/>
          <xsl:with-param name="pLeadPunct" select="$pLeadPunct"/>
          <xsl:with-param name="pTermPunct" select="$pTermPunct"/>
          <xsl:with-param name="pForceTerm" select="$pForceTerm"/>
          <xsl:with-param name="pChopParens" select="$pChopParens"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="substring($vNormString,1,1)='{{' and not(contains($vNormString,'}}'))">
        <xsl:call-template name="tChopPunct">
          <xsl:with-param name="pString" select="substring($vNormString,2)"/>
          <xsl:with-param name="pEndPunct" select="$pEndPunct"/>
          <xsl:with-param name="pLeadPunct" select="$pLeadPunct"/>
          <xsl:with-param name="pTermPunct" select="$pTermPunct"/>
          <xsl:with-param name="pForceTerm" select="$pForceTerm"/>
          <xsl:with-param name="pChopParens" select="$pChopParens"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="substring($vNormString,1,1)='&quot;' and not(contains(substring($vNormString,2),'&quot;'))">
        <xsl:call-template name="tChopPunct">
          <xsl:with-param name="pString" select="substring($vNormString,2)"/>
          <xsl:with-param name="pEndPunct" select="$pEndPunct"/>
          <xsl:with-param name="pLeadPunct" select="$pLeadPunct"/>
          <xsl:with-param name="pTermPunct" select="$pTermPunct"/>
          <xsl:with-param name="pForceTerm" select="$pForceTerm"/>
          <xsl:with-param name="pChopParens" select="$pChopParens"/>
        </xsl:call-template>
      </xsl:when>

      <!-- special handling for ending periods -->
      <!-- do not remove if we think it is an initial -->
      <!-- do not remove if we there there are multiple sentences -->
      <!-- do not fire if $pForceTerm = true() -->
      <xsl:when test="contains($pEndPunct,'.') and not($pForceTerm) and substring($vNormString,$vLength,1)='.'">
        <xsl:choose>
          <!-- Let's say it's an initial if the previous 2 characters are [ .][A-Z] -->
          <xsl:when test="contains($upper,substring($vNormString,$vLength - 1,1)) and
                          contains(' .',substring($vNormString,$vLength - 2,1))">
            <xsl:value-of select="$vNormString"/>
          </xsl:when>
          <!-- Let's say there are multiple sentences if terminal punctuation can be found in the rest of the string -->
          <xsl:when test="not(string-length(substring($vNormString,1,$vLength - 1)) = string-length(translate(substring($vNormString,1,$vLength - 1),$pTermPunct,'')))">
            <xsl:value-of select="$vNormString"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="tChopPunct">
              <xsl:with-param name="pString" select="substring($vNormString,1,$vLength - 1)"/>
              <xsl:with-param name="pEndPunct" select="$pEndPunct"/>
              <xsl:with-param name="pLeadPunct" select="$pLeadPunct"/>
              <xsl:with-param name="pTermPunct" select="$pTermPunct"/>
              <xsl:with-param name="pForceTerm" select="$pForceTerm"/>
              <xsl:with-param name="pChopParens" select="$pChopParens"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- generic case: strip ending punctuation -->
      <xsl:when test="contains($pEndPunct, substring($vNormString,$vLength,1))">
	<xsl:call-template name="tChopPunct">
	  <xsl:with-param name="pString" select="substring($vNormString,1,$vLength - 1)"/>
          <xsl:with-param name="pEndPunct" select="$pEndPunct"/>
          <xsl:with-param name="pLeadPunct" select="$pLeadPunct"/>
          <xsl:with-param name="pTermPunct" select="$pTermPunct"/>
          <xsl:with-param name="pForceTerm" select="$pForceTerm"/>
          <xsl:with-param name="pChopParens" select="$pChopParens"/>
	</xsl:call-template>
      </xsl:when>
      
      <!-- add matching square brackets if missing -->
      <xsl:when test="contains($vNormString,'[') and not(contains(substring-after($vNormString,'['),']'))">
        <xsl:value-of select="concat($vNormString,']')"/>
      </xsl:when>
      <xsl:when test="contains($vNormString,']') and not(contains(substring-before($vNormString,']'),'['))">
        <xsl:value-of select="concat('[',$vNormString)"/>
      </xsl:when>

      <xsl:otherwise>
	<xsl:value-of select="$vNormString"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="tLastIndex">
    <xsl:param name="pString"/>
    <xsl:param name="pSearch"/>
    <xsl:choose>
      <xsl:when test="$pSearch != '' and contains($pString,$pSearch)">
        <xsl:variable name="vRevSearch">
          <xsl:call-template name="tReverseString">
            <xsl:with-param name="pString" select="$pSearch"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="vRevString">
          <xsl:call-template name="tReverseString">
            <xsl:with-param name="pString" select="$pString"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="string-length($pString) - string-length(substring-before($vRevString,$vRevSearch))"/>
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="tReverseString">
    <xsl:param name="pString"/>
    <xsl:variable name="vLength" select="string-length($pString)"/>
    <xsl:choose>
      <xsl:when test="$vLength &lt; 2"><xsl:value-of select="$pString"/></xsl:when>
      <xsl:when test="$vLength = 2">
        <xsl:value-of select="concat(substring($pString,2,1),substring($pString,1,1))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="vMid" select="floor($vLength div 2)"/>
        <xsl:variable name="vHalf1">
          <xsl:call-template name="tReverseString">
            <xsl:with-param name="pString" select="substring($pString,1,$vMid)"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="vHalf2">
          <xsl:call-template name="tReverseString">
            <xsl:with-param name="pString" select="substring($pString,$vMid+1)"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="concat($vHalf2,$vHalf1)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      Chop [ ] from beginning and end of a string
  -->
  <xsl:template name="chopBrackets">
    <xsl:param name="chopString"/>
    <xsl:param name="punctuation">
      <xsl:text>.:,;/ </xsl:text>
    </xsl:param>
    <xsl:variable name="string">
      <xsl:call-template name="chopPunctuation">
	<xsl:with-param name="chopString" select="$chopString"/>
        <xsl:with-param name="punctuation" select="$punctuation"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="substring($string,1,1)='['">
        <xsl:call-template name="chopBrackets">
          <xsl:with-param name="chopString" select="substring-after($string,'[')"/>
          <xsl:with-param name="punctuation" select="$punctuation"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="substring($string,string-length($string),1) = ']'">
        <xsl:call-template name="chopBrackets">
          <xsl:with-param name="chopString" select="substring($string,1,string-length($string)-1)"/>
          <xsl:with-param name="punctuation" select="$punctuation"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$string"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      Chop ( ) from beginning and end of a string
  -->
  <xsl:template name="chopParens">
    <xsl:param name="chopString"/>
    <xsl:param name="punctuation">
      <xsl:text>.:,;/ </xsl:text>
    </xsl:param>
    <xsl:variable name="string">
      <xsl:call-template name="chopPunctuation">
	<xsl:with-param name="chopString" select="$chopString"/>
        <xsl:with-param name="punctuation" select="$punctuation"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="substring($string,1,1)='('">
        <xsl:call-template name="chopParens">
          <xsl:with-param name="chopString" select="substring-after($string,'(')"/>
          <xsl:with-param name="punctuation" select="$punctuation"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="substring($string,string-length($string),1) = ')'">
        <xsl:call-template name="chopParens">
          <xsl:with-param name="chopString" select="substring($string,1,string-length($string)-1)"/>
          <xsl:with-param name="punctuation" select="$punctuation"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$string"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      Chop leading padding character on string
      Used mostly to chop leading '0'
  -->
  <xsl:template name="chopLeadingPadding">
    <xsl:param name="chopString"/>
    <xsl:param name="padding" select="'0'"/>
    <xsl:variable name="length" select="string-length($chopString)"/>
    <xsl:choose>
      <xsl:when test="$length=0"/>
      <xsl:when test="contains($padding,substring($chopString,1,1))">
        <xsl:call-template name="chopLeadingPadding">
          <xsl:with-param name="chopString" select="substring($chopString,2)"/>
          <xsl:with-param name="padding" select="$padding"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$chopString"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!--
      Chop trailing punctuation
      .:,;/ and space
      From MARC21slimUtils.xsl
  -->
  <xsl:template name="chopPunctuation">
    <xsl:param name="chopString"/>
    <xsl:param name="punctuation">
      <xsl:text>.:,;/ </xsl:text>
    </xsl:param>
    <xsl:variable name="length" select="string-length($chopString)"/>
    <xsl:choose>
      <xsl:when test="$length=0"/>
      <xsl:when test="contains($punctuation, substring($chopString,$length,1))">
	<xsl:call-template name="chopPunctuation">
	  <xsl:with-param name="chopString" select="substring($chopString,1,$length - 1)"/>
	  <xsl:with-param name="punctuation" select="$punctuation"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:when test="not($chopString)"/>
      <xsl:otherwise>
	<xsl:value-of select="$chopString"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      generate a recordid base from user config
  -->
  <xsl:template match="marc:record" mode="recordid">
    <xsl:param name="baseuri" select="'http://example.org/'"/>
    <xsl:param name="idfield" select="'001'"/>
    <xsl:param name="recordno"/>
    <xsl:variable name="tag" select="substring($idfield,1,3)"/>
    <xsl:variable name="subfield">
      <xsl:choose>
        <xsl:when test="substring($idfield,4,1)">
          <xsl:value-of select="substring($idfield,4,1)"/>
        </xsl:when>
        <xsl:otherwise>a</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="recordid">
      <xsl:choose>
        <xsl:when test="$tag &lt; 10">
          <xsl:if test="count(marc:controlfield[@tag=$tag]) = 1">
            <xsl:call-template name="url-encode">
              <xsl:with-param name="str" select="normalize-space(marc:controlfield[@tag=$tag])"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="count(marc:datafield[@tag=$tag]/marc:subfield[@code=$subfield]) = 1">
            <xsl:call-template name="url-encode">
              <xsl:with-param name="str" select="normalize-space(marc:datafield[@tag=$tag]/marc:subfield[@code=$subfield])"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$recordid != ''">
        <xsl:value-of select="$baseuri"/><xsl:value-of select="$recordid"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="no">
          <xsl:text>WARNING: Unable to determine record ID for record </xsl:text><xsl:value-of select="$recordno"/><xsl:text>. Using generated ID.</xsl:text>
        </xsl:message>
        <xsl:value-of select="$baseuri"/><xsl:value-of select="generate-id(.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      create a space delimited label
      need to trim off the trailing space to use
  -->
  <xsl:template match="*" mode="concat-nodes-space">
    <xsl:value-of select="."/><xsl:text> </xsl:text>
  </xsl:template>

  <!--
      create a label with parameterized delimiter for a nodeset
      only add delimiter when there is no punctuation
      used in creating bf:provisionActivityStatement
  -->
  <xsl:template match="*" mode="concat-nodes-delimited">
    <xsl:param name="pDelimiter" select="';'"/>
    <xsl:param name="punctuation">
      <xsl:text>.:,;/</xsl:text>
    </xsl:param>
    <xsl:variable name="vValue" select="normalize-space(.)"/>
    <xsl:choose>
      <xsl:when test="position() = last()">
        <xsl:value-of select="$vValue"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$vValue=''"/>
          <xsl:when test="contains($punctuation, substring($vValue,string-length($vValue),1))">
            <xsl:value-of select="$vValue"/><xsl:text> </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$vValue"/><xsl:value-of select="$pDelimiter"/><xsl:text> </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      generate a marcKey for the subfields of a marc:datafield
      of the form $[code][text]$[code][text] etc.
  -->
  <xsl:template match="marc:subfield" mode="marcKey">
    <xsl:text>$</xsl:text><xsl:value-of select="@code"/><xsl:value-of select="."/>
  </xsl:template>

  <!--
      convert "u" or "U" to "X" for dates
  -->
  <xsl:template name="u2x">
    <xsl:param name="dateString"/>
    <xsl:choose>
      <xsl:when test="contains($dateString,'u')">
        <xsl:call-template name="u2x">
          <xsl:with-param name="dateString" select="concat(substring-before($dateString,'u'),'X',substring-after($dateString,'u'))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($dateString,'U')">
        <xsl:call-template name="u2x">
          <xsl:with-param name="dateString" select="concat(substring-before($dateString,'U'),'X',substring-after($dateString,'U'))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$dateString"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      convert a date string as from the 033/263 to an EDTF date
      (https://www.loc.gov/standards/datetime/pre-submission.html)
      with one difference - use 'X' for unspecified digits
  -->
  <xsl:template name="edtfFormat">
    <xsl:param name="pDateString"/>
    <!-- convert '-' to 'X' -->
    <xsl:choose>
      <xsl:when test="contains(substring($pDateString,1,12),'-')">
        <xsl:call-template name="edtfFormat">
          <xsl:with-param name="pDateString" select="concat(substring-before($pDateString,'-'),'X',substring-after($pDateString,'-'))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="vDatePart">
          <xsl:choose>
            <xsl:when test="substring($pDateString,7,2) != ''">
              <xsl:value-of select="concat(substring($pDateString,1,4),'-',substring($pDateString,5,2),'-',substring($pDateString,7,2))"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat(substring($pDateString,1,4),'-',substring($pDateString,5,2))"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vTimePart">
          <xsl:if test="substring($pDateString,9,4) != ''">
            <xsl:value-of select="concat('T',substring($pDateString,9,2),':',substring($pDateString,11,2),':00')"/>
          </xsl:if>
        </xsl:variable>
        <xsl:variable name="vTimeDiff">
          <xsl:if test="substring($pDateString,13,5) != ''">
            <xsl:value-of select="concat(substring($pDateString,13,3),':',substring($pDateString,16,2))"/>
          </xsl:if>
        </xsl:variable>
        <xsl:value-of select="concat($vDatePart,$vTimePart,$vTimeDiff)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      generate a property with a blank node Resource, and an rdfs:label
      process $3 and $2, if necessary
      Inspired by processing 340, may be useful elsewhere (actually
      not used by 340, but by other 3XX fields)
  -->

  <xsl:template match="marc:subfield" mode="generateProperty">
    <xsl:param name="serialization" select="'rdfxml'"/>
    <xsl:param name="pProp"/>
    <xsl:param name="pResource"/>
    <xsl:param name="pTarget"/>
    <xsl:param name="pLabel"/>
    <xsl:param name="pProcess"/>
    <xsl:param name="pPunctuation">
      <xsl:text>.:,;/ </xsl:text>
    </xsl:param>
    <xsl:param name="pVocabStem"/>
    <xsl:variable name="vXmlLang"><xsl:apply-templates select="../marc:datafield" mode="xmllang"/></xsl:variable>
    <xsl:variable name="vCurrentNode" select="generate-id(.)"/>
    <xsl:variable name="vLabel">
      <xsl:choose>
        <xsl:when test="$pLabel != ''"><xsl:value-of select="$pLabel"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$serialization = 'rdfxml'">
        <xsl:element name="{$pProp}">
          <xsl:element name="{$pResource}">
            <xsl:if test="$pTarget != ''">
              <xsl:attribute name="rdf:about"><xsl:value-of select="$pTarget"/></xsl:attribute>
            </xsl:if>
            <rdfs:label>
              <xsl:if test="$vXmlLang != ''">
                <xsl:attribute name="xml:lang"><xsl:value-of select="$vXmlLang"/></xsl:attribute>
              </xsl:if>
              <xsl:choose>
                <xsl:when test="$pProcess='chopPunctuation'">
                  <xsl:call-template name="chopPunctuation">
                    <xsl:with-param name="chopString"><xsl:value-of select="$vLabel"/></xsl:with-param>
                    <xsl:with-param name="punctuation" select="$pPunctuation"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:when test="$pProcess='chopParens'">
                  <xsl:call-template name="chopParens">
                    <xsl:with-param name="chopString"><xsl:value-of select="$vLabel"/></xsl:with-param>
                    <xsl:with-param name="punctuation" select="$pPunctuation"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:when test="$pProcess='chopBrackets'">
                  <xsl:call-template name="chopBrackets">
                    <xsl:with-param name="chopString"><xsl:value-of select="$vLabel"/></xsl:with-param>
                    <xsl:with-param name="punctuation" select="$pPunctuation"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="$vLabel"/></xsl:otherwise>
              </xsl:choose>
            </rdfs:label>
            <xsl:apply-templates select="following-sibling::marc:subfield[@code='0' and generate-id(preceding-sibling::marc:subfield[@code != '0'][1])=$vCurrentNode]" mode="subfield0orw">
              <xsl:with-param name="serialization" select="$serialization"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="../marc:subfield[@code='3']" mode="subfield3">
              <xsl:with-param name="serialization" select="$serialization"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="../marc:subfield[@code='2']" mode="subfield2">
              <xsl:with-param name="serialization" select="$serialization"/>
              <xsl:with-param name="pVocabStem" select="$pVocabStem"/>
            </xsl:apply-templates>
          </xsl:element>
        </xsl:element>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- get the tag ord of a datafield within a marc:record -->
  <xsl:template match="marc:datafield" mode="tagord">
    <xsl:variable name="vId" select="generate-id(.)"/>
    <xsl:for-each select="../marc:leader | ../marc:controlfield | ../marc:datafield">
      <xsl:if test="generate-id(.)=$vId"><xsl:value-of select="position()"/></xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!--
      URL encode a string, ASCII only
      based on https://skew.org/xml/stylesheets/url-encode/url-encode.xsl
  -->
  <xsl:template name="url-encode">
    <xsl:param name="str"/>   
    <xsl:variable name="ascii"> !"#$%&amp;'()*+,-./0123456789:;&lt;=&gt;?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~</xsl:variable>
    <xsl:variable name="safe">!'()*-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~</xsl:variable>
    <xsl:variable name="hex" >0123456789ABCDEF</xsl:variable>
    <xsl:if test="$str">
      <xsl:variable name="first-char" select="substring($str,1,1)"/>
      <xsl:choose>
        <xsl:when test="contains($safe,$first-char)">
          <xsl:value-of select="$first-char"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="codepoint">
            <xsl:choose>
              <xsl:when test="contains($ascii,$first-char)">
                <xsl:value-of select="string-length(substring-before($ascii,$first-char)) + 32"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:message terminate="no">Warning: string contains a character that is out of range! Substituting "?".</xsl:message>
                <xsl:text>63</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
        <xsl:variable name="hex-digit1" select="substring($hex,floor($codepoint div 16) + 1,1)"/>
        <xsl:variable name="hex-digit2" select="substring($hex,$codepoint mod 16 + 1,1)"/>
        <xsl:value-of select="concat('%',$hex-digit1,$hex-digit2)"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="string-length($str) &gt; 1">
        <xsl:call-template name="url-encode">
          <xsl:with-param name="str" select="substring($str,2)"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- Return a normalized code suitable for constructing a URI -->
  <xsl:template name="tNormalizeCode">
    <xsl:param name="pCode"/>
    <xsl:param name="pStripPunct" select="false()"/>
    <xsl:variable name="vCode">
      <xsl:choose>
        <!-- well, not all punctuation (e.g. quotes), but probably enough -->
        <xsl:when test="$pStripPunct">
          <xsl:value-of select="translate($pCode,'.?!,;:-/\()[]{} ','')"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$pCode"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="url-encode">
      <xsl:with-param name="str" select="translate(normalize-space($vCode),$upper,$lower)"/>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
