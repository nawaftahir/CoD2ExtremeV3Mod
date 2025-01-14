geoLocalize(country)
{
	if(!isDefined(country)) country = "UNKNOWN";

	switch(country)
	{
		case "AD": return(&"GEOLOCATION_AD"); // Andorra
		case "AE": return(&"GEOLOCATION_AE"); // United Arab Emirates
		case "AF": return(&"GEOLOCATION_AF"); // Afghanistan
		case "AG": return(&"GEOLOCATION_AG"); // Antigua and Barbuda
		case "AI": return(&"GEOLOCATION_AI"); // Anguilla
		case "AL": return(&"GEOLOCATION_AL"); // Albania
		case "AM": return(&"GEOLOCATION_AM"); // Armenia
		case "AN": return(&"GEOLOCATION_AN"); // Netherlands Antilles
		case "AO": return(&"GEOLOCATION_AO"); // Angola
		case "AP": return(&"GEOLOCATION_AP"); // Non-spec Asia Pas Location
		case "AQ": return(&"GEOLOCATION_AQ"); // Antarctica
		case "AR": return(&"GEOLOCATION_AR"); // Argentina
		case "AS": return(&"GEOLOCATION_AS"); // American Samoa
		case "AT": return(&"GEOLOCATION_AT"); // Austria
		case "AU": return(&"GEOLOCATION_AU"); // Australia
		case "AW": return(&"GEOLOCATION_AW"); // Aruba
		case "AX": return(&"GEOLOCATION_AX"); // Aland Islands
		case "AZ": return(&"GEOLOCATION_AZ"); // Azerbaijan
		case "BA": return(&"GEOLOCATION_BA"); // Bosnia and Herzegowina
		case "BB": return(&"GEOLOCATION_BB"); // Barbados
		case "BD": return(&"GEOLOCATION_BD"); // Bangladesh
		case "BE": return(&"GEOLOCATION_BE"); // Belgium
		case "BF": return(&"GEOLOCATION_BF"); // Burkina Faso
		case "BG": return(&"GEOLOCATION_BG"); // Bulgaria
		case "BH": return(&"GEOLOCATION_BH"); // Bahrain
		case "BI": return(&"GEOLOCATION_BI"); // Burundi
		case "BJ": return(&"GEOLOCATION_BJ"); // Benin
		case "BM": return(&"GEOLOCATION_BM"); // Bermuda
		case "BN": return(&"GEOLOCATION_BN"); // Brunei Darussalam
		case "BO": return(&"GEOLOCATION_BO"); // Bolivia
		case "BQ": return(&"GEOLOCATION_BQ"); // Bonaire; Sint Eustatius; Saba
		case "BR": return(&"GEOLOCATION_BR"); // Brazil
		case "BS": return(&"GEOLOCATION_BS"); // Bahamas
		case "BT": return(&"GEOLOCATION_BT"); // Bhutan
		case "BV": return(&"GEOLOCATION_BV"); // Bouvet Island
		case "BW": return(&"GEOLOCATION_BW"); // Botswana
		case "BY": return(&"GEOLOCATION_BY"); // Belarus
		case "BZ": return(&"GEOLOCATION_BZ"); // Belize
		case "CA": return(&"GEOLOCATION_CA"); // Canada
		case "CC": return(&"GEOLOCATION_CC"); // Cocos (keeling) Islands
		case "CD": return(&"GEOLOCATION_CD"); // Congo the Democratic Republic of the
		case "CF": return(&"GEOLOCATION_CF"); // Central African Republic
		case "CG": return(&"GEOLOCATION_CG"); // Congo
		case "CH": return(&"GEOLOCATION_CH"); // Switzerland
		case "CI": return(&"GEOLOCATION_CI"); // Cote D'ivoire
		case "CK": return(&"GEOLOCATION_CK"); // Cook Islands
		case "CL": return(&"GEOLOCATION_CL"); // Chile
		case "CM": return(&"GEOLOCATION_CM"); // Cameroon
		case "CN": return(&"GEOLOCATION_CN"); // China
		case "CO": return(&"GEOLOCATION_CO"); // Colombia
		case "CR": return(&"GEOLOCATION_CR"); // Costa Rica
		case "CS": return(&"GEOLOCATION_CS"); // Serbia and Montenegro
		case "CU": return(&"GEOLOCATION_CU"); // Cuba
		case "CV": return(&"GEOLOCATION_CV"); // Cape Verde
		case "CW": return(&"GEOLOCATION_CW"); // Curacao
		case "CX": return(&"GEOLOCATION_CX"); // Christmas Island
		case "CY": return(&"GEOLOCATION_CY"); // Cyprus
		case "CZ": return(&"GEOLOCATION_CZ"); // Czech Republic
		case "DE": return(&"GEOLOCATION_DE"); // Germany
		case "DJ": return(&"GEOLOCATION_DJ"); // Djibouti
		case "DK": return(&"GEOLOCATION_DK"); // Denmark
		case "DM": return(&"GEOLOCATION_DM"); // Dominica
		case "DO": return(&"GEOLOCATION_DO"); // Dominican Republic
		case "DZ": return(&"GEOLOCATION_DZ"); // Algeria
		case "EC": return(&"GEOLOCATION_EC"); // Ecuador
		case "EE": return(&"GEOLOCATION_EE"); // Estonia
		case "EG": return(&"GEOLOCATION_EG"); // Egypt
		case "EH": return(&"GEOLOCATION_EH"); // Western Sahara
		case "ER": return(&"GEOLOCATION_ER"); // Eritrea
		case "ES": return(&"GEOLOCATION_ES"); // Spain
		case "ET": return(&"GEOLOCATION_ET"); // Ethiopia
		case "EU": return(&"GEOLOCATION_EU"); // European Union
		case "FI": return(&"GEOLOCATION_FI"); // Finland
		case "FJ": return(&"GEOLOCATION_FJ"); // Fiji
		case "FK": return(&"GEOLOCATION_FK"); // Falkland Islands (malvinas)
		case "FM": return(&"GEOLOCATION_FM"); // Micronesia Federated States of
		case "FO": return(&"GEOLOCATION_FO"); // Faroe Islands
		case "FR": return(&"GEOLOCATION_FR"); // France
		case "FX": return(&"GEOLOCATION_FX"); // France Metro
		case "GA": return(&"GEOLOCATION_GA"); // Gabon
		case "GB": return(&"GEOLOCATION_GB"); // United Kingdom
		case "GD": return(&"GEOLOCATION_GD"); // Grenada
		case "GE": return(&"GEOLOCATION_GE"); // Georgia
		case "GF": return(&"GEOLOCATION_GF"); // French Guiana
		case "GG": return(&"GEOLOCATION_GG"); // Guernsey
		case "GH": return(&"GEOLOCATION_GH"); // Ghana
		case "GI": return(&"GEOLOCATION_GI"); // Gibraltar
		case "GL": return(&"GEOLOCATION_GL"); // Greenland
		case "GM": return(&"GEOLOCATION_GM"); // Gambia
		case "GN": return(&"GEOLOCATION_GN"); // Guinea
		case "GP": return(&"GEOLOCATION_GP"); // Guadeloupe
		case "GQ": return(&"GEOLOCATION_GQ"); // Equatorial Guinea
		case "GR": return(&"GEOLOCATION_GR"); // Greece
		case "GS": return(&"GEOLOCATION_GS"); // South Georgia and the South Sandwich Islands
		case "GT": return(&"GEOLOCATION_GT"); // Guatemala
		case "GU": return(&"GEOLOCATION_GU"); // Guam
		case "GW": return(&"GEOLOCATION_GW"); // Guinea-bissau
		case "GY": return(&"GEOLOCATION_GY"); // Guyana
		case "HK": return(&"GEOLOCATION_HK"); // Hong Kong
		case "HM": return(&"GEOLOCATION_HM"); // Heard and Mc Donald Islands
		case "HN": return(&"GEOLOCATION_HN"); // Honduras
		case "HR": return(&"GEOLOCATION_HR"); // Croatia (local Name: Hrvatska)
		case "HT": return(&"GEOLOCATION_HT"); // Haiti
		case "HU": return(&"GEOLOCATION_HU"); // Hungary
		case "ID": return(&"GEOLOCATION_ID"); // Indonesia
		case "IE": return(&"GEOLOCATION_IE"); // Ireland
		case "IL": return(&"GEOLOCATION_IL"); // Israel
		case "IM": return(&"GEOLOCATION_IM"); // Isle of Man
		case "IN": return(&"GEOLOCATION_IN"); // India
		case "IO": return(&"GEOLOCATION_IO"); // British Indian Ocean Territory
		case "IQ": return(&"GEOLOCATION_IQ"); // Iraq
		case "IR": return(&"GEOLOCATION_IR"); // Iran (islamic Republic Of)
		case "IS": return(&"GEOLOCATION_IS"); // Iceland
		case "IT": return(&"GEOLOCATION_IT"); // Italy
		case "JE": return(&"GEOLOCATION_JE"); // Jersey
		case "JM": return(&"GEOLOCATION_JM"); // Jamaica
		case "JO": return(&"GEOLOCATION_JO"); // Jordan
		case "JP": return(&"GEOLOCATION_JP"); // Japan
		case "KE": return(&"GEOLOCATION_KE"); // Kenya
		case "KG": return(&"GEOLOCATION_KG"); // Kyrgyzstan
		case "KH": return(&"GEOLOCATION_KH"); // Cambodia
		case "KI": return(&"GEOLOCATION_KI"); // Kiribati
		case "KM": return(&"GEOLOCATION_KM"); // Comoros
		case "KN": return(&"GEOLOCATION_KN"); // Saint Kitts and Nevis
		case "KP": return(&"GEOLOCATION_KP"); // Korea Democratic People's Republic of
		case "KR": return(&"GEOLOCATION_KR"); // Korea Republic of
		case "KW": return(&"GEOLOCATION_KW"); // Kuwait
		case "KY": return(&"GEOLOCATION_KY"); // Cayman Islands
		case "KZ": return(&"GEOLOCATION_KZ"); // Kazakhstan
		case "LA": return(&"GEOLOCATION_LA"); // Lao People's Democratic Republic
		case "LB": return(&"GEOLOCATION_LB"); // Lebanon
		case "LC": return(&"GEOLOCATION_LC"); // Saint Lucia
		case "LI": return(&"GEOLOCATION_LI"); // Liechtenstein
		case "LK": return(&"GEOLOCATION_LK"); // Sri Lanka
		case "LR": return(&"GEOLOCATION_LR"); // Liberia
		case "LS": return(&"GEOLOCATION_LS"); // Lesotho
		case "LT": return(&"GEOLOCATION_LT"); // Lithuania
		case "LU": return(&"GEOLOCATION_LU"); // Luxembourg
		case "LV": return(&"GEOLOCATION_LV"); // Latvia
		case "LY": return(&"GEOLOCATION_LY"); // Libyan Arab Jamahiriya
		case "MA": return(&"GEOLOCATION_MA"); // Morocco
		case "MC": return(&"GEOLOCATION_MC"); // Monaco
		case "MD": return(&"GEOLOCATION_MD"); // Moldova Republic of
		case "ME": return(&"GEOLOCATION_ME"); // Montenegro
		case "MF": return(&"GEOLOCATION_MF"); // Saint Martin
		case "MG": return(&"GEOLOCATION_MG"); // Madagascar
		case "MH": return(&"GEOLOCATION_MH"); // Marshall Islands
		case "MK": return(&"GEOLOCATION_MK"); // Macedonia
		case "ML": return(&"GEOLOCATION_ML"); // Mali
		case "MM": return(&"GEOLOCATION_MM"); // Myanmar
		case "MN": return(&"GEOLOCATION_MN"); // Mongolia
		case "MO": return(&"GEOLOCATION_MO"); // Macau
		case "MP": return(&"GEOLOCATION_MP"); // Northern Mariana Islands
		case "MQ": return(&"GEOLOCATION_MQ"); // Martinique
		case "MR": return(&"GEOLOCATION_MR"); // Mauritania
		case "MS": return(&"GEOLOCATION_MS"); // Montserrat
		case "MT": return(&"GEOLOCATION_MT"); // Malta
		case "MU": return(&"GEOLOCATION_MU"); // Mauritius
		case "MV": return(&"GEOLOCATION_MV"); // Maldives
		case "MW": return(&"GEOLOCATION_MW"); // Malawi
		case "MX": return(&"GEOLOCATION_MX"); // Mexico
		case "MY": return(&"GEOLOCATION_MY"); // Malaysia
		case "MZ": return(&"GEOLOCATION_MZ"); // Mozambique
		case "NA": return(&"GEOLOCATION_NA"); // Namibia
		case "NC": return(&"GEOLOCATION_NC"); // New Caledonia
		case "NE": return(&"GEOLOCATION_NE"); // Niger
		case "NF": return(&"GEOLOCATION_NF"); // Norfolk Island
		case "NG": return(&"GEOLOCATION_NG"); // Nigeria
		case "NI": return(&"GEOLOCATION_NI"); // Nicaragua
		case "NL": return(&"GEOLOCATION_NL"); // Netherlands
		case "NO": return(&"GEOLOCATION_NO"); // Norway
		case "NP": return(&"GEOLOCATION_NP"); // Nepal
		case "NR": return(&"GEOLOCATION_NR"); // Nauru
		case "NU": return(&"GEOLOCATION_NU"); // Niue
		case "NZ": return(&"GEOLOCATION_NZ"); // New Zealand
		case "OM": return(&"GEOLOCATION_OM"); // Oman
		case "PA": return(&"GEOLOCATION_PA"); // Panama
		case "PE": return(&"GEOLOCATION_PE"); // Peru
		case "PF": return(&"GEOLOCATION_PF"); // French Polynesia
		case "PG": return(&"GEOLOCATION_PG"); // Papua New Guinea
		case "PH": return(&"GEOLOCATION_PH"); // Philippines
		case "PK": return(&"GEOLOCATION_PK"); // Pakistan
		case "PL": return(&"GEOLOCATION_PL"); // Poland
		case "PM": return(&"GEOLOCATION_PM"); // St. Pierre and Miquelon
		case "PN": return(&"GEOLOCATION_PN"); // Pitcairn
		case "PR": return(&"GEOLOCATION_PR"); // Puerto Rico
		case "PS": return(&"GEOLOCATION_PS"); // Palestinian Territory Occupied
		case "PT": return(&"GEOLOCATION_PT"); // Portugal
		case "PW": return(&"GEOLOCATION_PW"); // Palau
		case "PY": return(&"GEOLOCATION_PY"); // Paraguay
		case "QA": return(&"GEOLOCATION_QA"); // Qatar
		case "RE": return(&"GEOLOCATION_RE"); // Reunion
		case "RO": return(&"GEOLOCATION_RO"); // Romania
		case "RS": return(&"GEOLOCATION_RS"); // Serbia
		case "RU": return(&"GEOLOCATION_RU"); // Russian Federation
		case "RW": return(&"GEOLOCATION_RW"); // Rwanda
		case "SA": return(&"GEOLOCATION_SA"); // Saudi Arabia
		case "SB": return(&"GEOLOCATION_SB"); // Solomon Islands
		case "SC": return(&"GEOLOCATION_SC"); // Seychelles
		case "SD": return(&"GEOLOCATION_SD"); // Sudan
		case "SE": return(&"GEOLOCATION_SE"); // Sweden
		case "SG": return(&"GEOLOCATION_SG"); // Singapore
		case "SH": return(&"GEOLOCATION_SH"); // Saint Helena
		case "SI": return(&"GEOLOCATION_SI"); // Slovenia
		case "SJ": return(&"GEOLOCATION_SJ"); // Svalbard and Jan Mayen Islands
		case "SK": return(&"GEOLOCATION_SK"); // Slovakia (slovak Republic)
		case "SL": return(&"GEOLOCATION_SL"); // Sierra Leone
		case "SM": return(&"GEOLOCATION_SM"); // San Marino
		case "SN": return(&"GEOLOCATION_SN"); // Senegal
		case "SO": return(&"GEOLOCATION_SO"); // Somalia
		case "SR": return(&"GEOLOCATION_SR"); // Suriname
		case "SS": return(&"GEOLOCATION_SS"); // South Sudan
		case "ST": return(&"GEOLOCATION_ST"); // Sao Tome and Principe
		case "SV": return(&"GEOLOCATION_SV"); // El Salvador
		case "SX": return(&"GEOLOCATION_SX"); // Sint Maarten
		case "SY": return(&"GEOLOCATION_SY"); // Syrian Arab Republic
		case "SZ": return(&"GEOLOCATION_SZ"); // Swaziland
		case "TC": return(&"GEOLOCATION_TC"); // Turks and Caicos Islands
		case "TD": return(&"GEOLOCATION_TD"); // Chad
		case "TF": return(&"GEOLOCATION_TF"); // French Southern Territories
		case "TG": return(&"GEOLOCATION_TG"); // Togo
		case "TH": return(&"GEOLOCATION_TH"); // Thailand
		case "TJ": return(&"GEOLOCATION_TJ"); // Tajikistan
		case "TK": return(&"GEOLOCATION_TK"); // Tokelau
		case "TL": return(&"GEOLOCATION_TL"); // Timor-leste
		case "TM": return(&"GEOLOCATION_TM"); // Turkmenistan
		case "TN": return(&"GEOLOCATION_TN"); // Tunisia
		case "TO": return(&"GEOLOCATION_TO"); // Tonga
		case "TR": return(&"GEOLOCATION_TR"); // Turkey
		case "TT": return(&"GEOLOCATION_TT"); // Trinidad and Tobago
		case "TV": return(&"GEOLOCATION_TV"); // Tuvalu
		case "TW": return(&"GEOLOCATION_TW"); // Taiwan; Republic of China (roc)
		case "TZ": return(&"GEOLOCATION_TZ"); // Tanzania United Republic of
		case "UA": return(&"GEOLOCATION_UA"); // Ukraine
		case "UG": return(&"GEOLOCATION_UG"); // Uganda
		case "UK": return(&"GEOLOCATION_UK"); // United Kingdom
		case "UM": return(&"GEOLOCATION_UM"); // United States Minor Outlying Islands
		case "US": return(&"GEOLOCATION_US"); // United States
		case "UY": return(&"GEOLOCATION_UY"); // Uruguay
		case "UZ": return(&"GEOLOCATION_UZ"); // Uzbekistan
		case "VA": return(&"GEOLOCATION_VA"); // Holy See (vatican City State)
		case "VC": return(&"GEOLOCATION_VC"); // Saint Vincent and the Grenadines
		case "VE": return(&"GEOLOCATION_VE"); // Venezuela
		case "VG": return(&"GEOLOCATION_VG"); // Virgin Islands (british)
		case "VI": return(&"GEOLOCATION_VI"); // Virgin Islands (u.s.)
		case "VN": return(&"GEOLOCATION_VN"); // Viet Nam
		case "VU": return(&"GEOLOCATION_VU"); // Vanuatu
		case "WF": return(&"GEOLOCATION_WF"); // Wallis and Futuna Islands
		case "WS": return(&"GEOLOCATION_WS"); // Samoa
		case "YE": return(&"GEOLOCATION_YE"); // Yemen
		case "YT": return(&"GEOLOCATION_YT"); // Mayotte
		case "YU": return(&"GEOLOCATION_YU"); // Serbia and Montenegro
		case "ZA": return(&"GEOLOCATION_ZA"); // South Africa
		case "ZM": return(&"GEOLOCATION_ZM"); // Zambia
		case "ZW": return(&"GEOLOCATION_ZW"); // Zimbabwe
		case "ZZ": return(&"GEOLOCATION_ZZ"); // Reserved
		case "UNKNOWN":
		default: return(&"GEOLOCATION_UNKNOWN");
	}
}
