#!/bin/bash

gawk -F "\t" -v sFileInfo=$1 -e '
		function readTimeStamp(sFmtTime, sTime, sFmtDate, sDate, \
			arrDate, arrTime, sLine)
		{
			# sFmtTime
			#	is of the form H[H]:M[M]:S[S]
			#	where if you have HH it means that the hour is zero-padded
			#	and if you have H it means that the hour is not zero-padded
			#	so for example a format of
			#			HH:M.s
			#	would mean that the length of the time string varies from 
			#	6 to 8 characters, the hour is zero-padded,
			#	minutes and seconds are not, also the separator between
			#	the hour field and minutes field is different from that
			#	between the minutes field and the seconds field.
			#
			# sFmtDate
			#	is in the form YYYY.M[M].D[D] and it uses the same
			#	logic from sFmtTime with the exception that the year part
			#	always has the century part: for example you cannot say
			#	"56.12.31" with the format "YY.MM.DD" and hope to
			#	get a value for the last day of let`s say the year 2056
			#	Observations:
			#	* if you have a situation where the input has only two
			#	digits for the year, then you should know what century
			#	you are in and before you call this function you should
			#	concatenate the century part to the rest of the digits.
			#	* There is the possibility that you have a year field
			#	> 9999; if this is happening, you may have to rewrite
			#	this function, and also it is odd that you still use this
			#	after ~8000 years!!!

			decodeFieldString(sFmtTime, sTime, arrTime)
			decodeFieldString(sFmtDate, sDate, arrDate)

			return mktime(	nullTest(arrDate["YYYY"]) " " \
							nullTest(arrDate["MM"]) " " \
							nullTest(arrDate["DD"]) " " \
							nullTest(arrTime["HH"]) " " \
							nullTest(arrTime["MM"])" " \
							nullTest(arrTime["SS"])	)
		}
		function nullTest(sField){
			if(length (sField) == 0)
				return "0"
			else
				return sField
		}

		function decodeFieldString(sFmt, sField, arField, \
						sDelims, i, arDelims, arMeanings, arValues)
		{
			split(sFmt, arDelims, "H{1,2}|M{1,2}|S{1,2}|D{1,2}|Y{4}")
			# with this split we cover all 6 fields of interest:
			# we use the "HMSDY" letters as delimiters for the split
			# function in order to get the actual delimiters, because
			# we know what we expect from the users if they use the
			# specified format for the format string

			sDelims = ""
			for (i in arDelims)
				sDelims = concatDelims(sDelims, arDelims[i])
			# the sDelims serves the same function as the "H{12}|...Y{4}"
			# string above; as a result we read the delimiters that the
			# users have in their format

			split(sFmt, arMeanings, sDelims)
			split(sField, arValues, sDelims)

			# After these two splits we have the values and meanings
			# arrays populated. Example:
			# for a				sField string like	"2011-02-11"
			# combined with a	sFmt string like	"YYYY-MM-DD" we have:

			#		arMeanings[1] = "YYYY"	& arValues[1] = "2011"
			#		arMeanings[2] = "MM"	& arValues[2] = "02"
			#		arMeanings[3] = "DD"	& arValues[3] = "11"
			# note the correspondence between the indices because we`re
			# gonna use it below


			for (i in arMeanings)
				# in this for loop we combine our "return" array in the form:
				#	arField["YYYY"]	= "2011"
				# 	arField["MM"]	= "02"
				# 	arField["DD"]	= "11"
				# (from the previous example)
				# Observation:	we have here an example with a date value,
				# 				but it works with time values as well
			{
				if (length(arValues[i]) == 1)
					arValues[i] = "0" arValues[i]

				if (index(arMeanings[i], "D") != 0)
					arField["DD"] = arValues[i]

				if (index(arMeanings[i], "M") != 0)
					arField["MM"] = arValues[i]

				if (index(arMeanings[i], "Y") != 0)
					arField["YYYY"] = arValues[i]

				if (index(arMeanings[i], "H") != 0)
					arField["HH"] = arValues[i]

				if (index(arMeanings[i], "S") != 0)
					arField["SS"] = arValues[i]
 			}
		}

		function writeTimeStamp(sFmt, iTimeStamp,\
				i,j,k, arDelims, sDelims, sTrfs, \
				arMeanings, arSingleDigitReg, arSingleDigitRepl)
		# this function uses the same format as readTimeStamp so
		# check that out
		{
			split(sFmt, arDelims, "M{1,2}|D{1,2}|Y{4}|H{1,2}|S{1,2}")
			sDelims = ""
			for (i in arDelims)
				sDelims = concatDelims(sDelims, arDelims[i])
			split(sFmt, arMeanings, sDelims)
			sTrfs = ""	# string for strftime
			j = 2		# j: index for the "current delimiter"
			k = 1		# k: index/flag: when not all values are zero-padded
			for (i in arMeanings) {
				if (index (arMeanings[i], "Y") != 0)
					sTrfs = sTrfs "%Y"
				if (index (arMeanings[i], "M") != 0)
					if (index(sFmt, "Y") != 0)
						# we have a year substring so we return a date string
						sTrfs = sTrfs "%m"
					else
						sTrfs = sTrfs "%M"
				if (index (arMeanings[i], "H") != 0)
					sTrfs = sTrfs "%H"
				if (index (arMeanings[i], "S") != 0)
					sTrfs = sTrfs "%S"
				if (index (arMeanings[i], "D") != 0)
						sTrfs = sTrfs "%d"
				if (length(arMeanings[i]) == 1)
					if (i == 1){
						arSingleDigitReg[k]="0{0,1}"
						arSingleDigitRepl[k++]=""
					} else {
						arSingleDigitReg[k] = \
							escapedDelim(arDelims[j-1])"0{0,1}"
						arSingleDigitRepl[k++] = arDelims[j-1]
					}
				sTrfs = sTrfs arDelims[j++]
			}

			if ( k == 1 )
				# here we use k == 1 as a flag for the fact that we (don`t)
				# have zero-padding in any of the fields.
				# if you change(d) the meaning of k, then you should also
				# add here the necessary boolean
				return strftime(sTrfs, iTimeStamp)
			else {
				sDelims = strftime(sTrfs, iTimeStamp) # sDelims is reused !!
				for (i in arSingleDigitReg)
					sub(	arSingleDigitReg[i], \
							arSingleDigitRepl[i],\
							sDelims)
				return sDelims
			}
		}

		function concatDelims(sOldDelims, cAdelim){
			return sOldDelims escapedDelim(cAdelim) "{1}|"
		}

		function escapedDelim(cAdelim){
			if (index(".[]()\\$", cAdelim) > 0)
				return "\\" cAdelim
			else
				return cAdelim
		}

		function decodeFileInfo(sCode, aInfo)
		{
			if (length(sCode) > 0){
				split(sCode, aInfo, "#")
			}
		}

	BEGIN {
			decodeFileInfo(sFileInfo, myInfo)
			iInfo = 1
			while(iInfo <= length(myInfo) - 1){
				# print myInfo[iInfo]
				if (index(myInfo[iInfo+1], "Y") > 0){
					colDay = myInfo[iInfo]
					sub("C[0]{0,1}", "", colDay)
					colDay = strtonum(colDay)
					sFmtDay = myInfo[iInfo+1]
				}
				else
				{
					colTime = myInfo[iInfo]
					sub("C[0]{0,1}", "", colTime)
					colTime = strtonum(colTime)
					# colTime = strtonum(sub("C[0]{0,1}", "", myInfo[iInfo]))
					sFmtTime = myInfo[iInfo+1]
				}
				iInfo+=2
			}
			myShift=strtonum(myInfo[iInfo])
			OFS = FS
		}
		{
			# print
			if (myShift != 0){
				rowTimeStamp = myShift + readTimeStamp(sFmtTime, $colTime, \
				 sFmtDay, $colDay)
				$colDay = writeTimeStamp(sFmtDay, rowTimeStamp)
				$colTime = writeTimeStamp(sFmtTime, rowTimeStamp)
			}
			print
		}'
