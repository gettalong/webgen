# -*- encoding: utf-8 -*-

module Webgen

  # Describes a human language which is uniquely identfied by a three letter code and, optionally,
  # by an alternative three letter or a two letter code.
  class Language

    include Comparable

    # An array containing the language codes for the language.
    attr_reader :codes

    # The english description of the language.
    attr_reader :description

    # Create a new language. +codes+ has to be an array containing three strings: the three letter
    # code, the alternative three letter code and the two letter code. If one is not available for
    # the language, it has to be +nil+.
    def initialize(codes, description)
      @codes = codes
      @description = description
    end

    # The two letter code.
    def code2chars
      @codes[2]
    end

    # The three letter code.
    def code3chars
      @codes[0]
    end

    # The alternative three letter code.
    def code3chars_alternative
      @codes[1]
    end

    # The textual representation of the language.
    def to_s
      code2chars || code3chars
    end

    alias_method :to_str, :to_s

    def inspect #:nodoc:
      "#<Language codes=#{codes.inspect} description=#{description.inspect}>"
    end

    def <=>(other) #:nodoc:
      self.to_s <=> other.to_s
    end

    def eql?(other) #:nodoc:
      (other.is_a?(self.class) && other.to_s == self.to_s) ||
        (other.is_a?(String) && self.to_s == other)
    end

    def hash #:nodoc:
      self.to_s.hash
    end

  end


  # Used for managing human languages.
  module LanguageManager

    # Return a +Language+ object for the given language code or +nil+ if no such object exists.
    def self.language_for_code(code)
      languages[code]
    end

    # Return an array of +Language+ objects whose description match the given +text+.
    def self.find_language(text)
      languages.values.find_all {|lang| /.*#{Regexp.escape(text)}.*/i =~ lang.description}.uniq.sort
    end

    # Return all available languages as a Hash. The keys are the language codes and the values are
    # the +Language+ objects for them.
    def self.languages
      unless defined?(@@languages)
        @@languages = {}
        started = nil
        data = File.readlines(__FILE__).each do |l|
          next unless (started ||= (l == "aar||aa|Afar|afar\n"))
          data = l.chomp.split('|').collect {|f| f.empty? ? nil : f}
          lang = Language.new(data[0..2], data[3])
          @@languages[lang] = lang
          @@languages[lang.code2chars] ||= lang unless lang.code2chars.nil?
          @@languages[lang.code3chars] ||= lang unless lang.code3chars.nil?
          @@languages[lang.code3chars_alternative] ||= lang unless lang.code3chars_alternative.nil?
        end
        @@languages.freeze
      end
      @@languages
    end

  end

end

__END__
aar||aa|Afar|afar
abk||ab|Abkhazian|abkhaze
ace|||Achinese|aceh
ach|||Acoli|acoli
ada|||Adangme|adangme
ady|||Adyghe; Adygei|adyghé
afa|||Afro-Asiatic (Other)|afro-asiatiques, autres langues
afh|||Afrihili|afrihili
afr||af|Afrikaans|afrikaans
ain|||Ainu|aïnou
aka||ak|Akan|akan
akk|||Akkadian|akkadien
alb|sqi|sq|Albanian|albanais
ale|||Aleut|aléoute
alg|||Algonquian languages|algonquines, langues
alt|||Southern Altai|altai du Sud
amh||am|Amharic|amharique
ang|||English, Old (ca.450-1100)|anglo-saxon (ca.450-1100)
anp|||Angika|angika
apa|||Apache languages|apache
ara||ar|Arabic|arabe
arc|||Official Aramaic (700-300 BCE); Imperial Aramaic (700-300 BCE)|araméen d'empire (700-300 BCE)
arg||an|Aragonese|aragonais
arm|hye|hy|Armenian|arménien
arn|||Mapudungun; Mapuche|mapudungun; mapuche; mapuce
arp|||Arapaho|arapaho
art|||Artificial (Other)|artificielles, autres langues
arw|||Arawak|arawak
asm||as|Assamese|assamais
ast|||Asturian; Bable; Leonese; Asturleonese|asturien; bable; léonais; asturoléonais
ath|||Athapascan languages|athapascanes, langues
aus|||Australian languages|australiennes, langues
ava||av|Avaric|avar
ave||ae|Avestan|avestique
awa|||Awadhi|awadhi
aym||ay|Aymara|aymara
aze||az|Azerbaijani|azéri
bad|||Banda languages|banda, langues
bai|||Bamileke languages|bamilékés, langues
bak||ba|Bashkir|bachkir
bal|||Baluchi|baloutchi
bam||bm|Bambara|bambara
ban|||Balinese|balinais
baq|eus|eu|Basque|basque
bas|||Basa|basa
bat|||Baltic (Other)|baltiques, autres langues
bej|||Beja; Bedawiyet|bedja
bel||be|Belarusian|biélorusse
bem|||Bemba|bemba
ben||bn|Bengali|bengali
ber|||Berber (Other)|berbères, autres langues
bho|||Bhojpuri|bhojpuri
bih||bh|Bihari|bihari
bik|||Bikol|bikol
bin|||Bini; Edo|bini; edo
bis||bi|Bislama|bichlamar
bla|||Siksika|blackfoot
bnt|||Bantu (Other)|bantoues, autres langues
bos||bs|Bosnian|bosniaque
bra|||Braj|braj
bre||br|Breton|breton
btk|||Batak languages|batak, langues
bua|||Buriat|bouriate
bug|||Buginese|bugi
bul||bg|Bulgarian|bulgare
bur|mya|my|Burmese|birman
byn|||Blin; Bilin|blin; bilen
cad|||Caddo|caddo
cai|||Central American Indian (Other)|indiennes d'Amérique centrale, autres langues
car|||Galibi Carib|karib; galibi; carib
cat||ca|Catalan; Valencian|catalan; valencien
cau|||Caucasian (Other)|caucasiennes, autres langues
ceb|||Cebuano|cebuano
cel|||Celtic (Other)|celtiques, autres langues
cha||ch|Chamorro|chamorro
chb|||Chibcha|chibcha
che||ce|Chechen|tchétchène
chg|||Chagatai|djaghataï
chi|zho|zh|Chinese|chinois
chk|||Chuukese|chuuk
chm|||Mari|mari
chn|||Chinook jargon|chinook, jargon
cho|||Choctaw|choctaw
chp|||Chipewyan; Dene Suline|chipewyan
chr|||Cherokee|cherokee
chu||cu|Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic|slavon d'église; vieux slave; slavon liturgique; vieux bulgare
chv||cv|Chuvash|tchouvache
chy|||Cheyenne|cheyenne
cmc|||Chamic languages|chames, langues
cop|||Coptic|copte
cor||kw|Cornish|cornique
cos||co|Corsican|corse
cpe|||Creoles and pidgins, English based (Other)|créoles et pidgins anglais, autres
cpf|||Creoles and pidgins, French-based (Other)|créoles et pidgins français, autres
cpp|||Creoles and pidgins, Portuguese-based (Other)|créoles et pidgins portugais, autres
cre||cr|Cree|cree
crh|||Crimean Tatar; Crimean Turkish|tatar de Crimé
crp|||Creoles and pidgins (Other)|créoles et pidgins divers
csb|||Kashubian|kachoube
cus|||Cushitic (Other)|couchitiques, autres langues
cze|ces|cs|Czech|tchèque
dak|||Dakota|dakota
dan||da|Danish|danois
dar|||Dargwa|dargwa
day|||Land Dayak languages|dayak, langues
del|||Delaware|delaware
den|||Slave (Athapascan)|esclave (athapascan)
dgr|||Dogrib|dogrib
din|||Dinka|dinka
div||dv|Divehi; Dhivehi; Maldivian|maldivien
doi|||Dogri|dogri
dra|||Dravidian (Other)|dravidiennes, autres langues
dsb|||Lower Sorbian|bas-sorabe
dua|||Duala|douala
dum|||Dutch, Middle (ca.1050-1350)|néerlandais moyen (ca. 1050-1350)
dut|nld|nl|Dutch; Flemish|néerlandais; flamand
dyu|||Dyula|dioula
dzo||dz|Dzongkha|dzongkha
efi|||Efik|efik
egy|||Egyptian (Ancient)|égyptien
eka|||Ekajuk|ekajuk
elx|||Elamite|élamite
eng||en|English|anglais
enm|||English, Middle (1100-1500)|anglais moyen (1100-1500)
epo||eo|Esperanto|espéranto
est||et|Estonian|estonien
ewe||ee|Ewe|éwé
ewo|||Ewondo|éwondo
fan|||Fang|fang
fao||fo|Faroese|féroïen
fat|||Fanti|fanti
fij||fj|Fijian|fidjien
fil|||Filipino; Pilipino|filipino; pilipino
fin||fi|Finnish|finnois
fiu|||Finno-Ugrian (Other)|finno-ougriennes, autres langues
fon|||Fon|fon
fre|fra|fr|French|français
frm|||French, Middle (ca.1400-1600)|français moyen (1400-1600)
fro|||French, Old (842-ca.1400)|français ancien (842-ca.1400)
frr|||Northern Frisian|frison septentrional
frs|||Eastern Frisian|frison oriental
fry||fy|Western Frisian|frison occidental
ful||ff|Fulah|peul
fur|||Friulian|frioulan
gaa|||Ga|ga
gay|||Gayo|gayo
gba|||Gbaya|gbaya
gem|||Germanic (Other)|germaniques, autres langues
geo|kat|ka|Georgian|géorgien
ger|deu|de|German|allemand
gez|||Geez|guèze
gil|||Gilbertese|kiribati
gla||gd|Gaelic; Scottish Gaelic|gaélique; gaélique écossais
gle||ga|Irish|irlandais
glg||gl|Galician|galicien
glv||gv|Manx|manx; mannois
gmh|||German, Middle High (ca.1050-1500)|allemand, moyen haut (ca. 1050-1500)
goh|||German, Old High (ca.750-1050)|allemand, vieux haut (ca. 750-1050)
gon|||Gondi|gond
gor|||Gorontalo|gorontalo
got|||Gothic|gothique
grb|||Grebo|grebo
grc|||Greek, Ancient (to 1453)|grec ancien (jusqu'à 1453)
gre|ell|el|Greek, Modern (1453-)|grec moderne (après 1453)
grn||gn|Guarani|guarani
gsw|||Swiss German; Alemannic; Alsatian|suisse alémanique; alémanique; alsacien
guj||gu|Gujarati|goudjrati
gwi|||Gwich'in|gwich'in
hai|||Haida|haida
hat||ht|Haitian; Haitian Creole|haïtien; créole haïtien
hau||ha|Hausa|haoussa
haw|||Hawaiian|hawaïen
heb||he|Hebrew|hébreu
her||hz|Herero|herero
hil|||Hiligaynon|hiligaynon
him|||Himachali|himachali
hin||hi|Hindi|hindi
hit|||Hittite|hittite
hmn|||Hmong|hmong
hmo||ho|Hiri Motu|hiri motu
hsb|||Upper Sorbian|haut-sorabe
hun||hu|Hungarian|hongrois
hup|||Hupa|hupa
iba|||Iban|iban
ibo||ig|Igbo|igbo
ice|isl|is|Icelandic|islandais
ido||io|Ido|ido
iii||ii|Sichuan Yi; Nuosu|yi de Sichuan
ijo|||Ijo languages|ijo, langues
iku||iu|Inuktitut|inuktitut
ile||ie|Interlingue; Occidental|interlingue
ilo|||Iloko|ilocano
ina||ia|Interlingua (International Auxiliary Language Association)|interlingua (langue auxiliaire internationale)
inc|||Indic (Other)|indo-aryennes, autres langues
ind||id|Indonesian|indonésien
ine|||Indo-European (Other)|indo-européennes, autres langues
inh|||Ingush|ingouche
ipk||ik|Inupiaq|inupiaq
ira|||Iranian (Other)|iraniennes, autres langues
iro|||Iroquoian languages|iroquoises, langues (famille)
ita||it|Italian|italien
jav||jv|Javanese|javanais
jbo|||Lojban|lojban
jpn||ja|Japanese|japonais
jpr|||Judeo-Persian|judéo-persan
jrb|||Judeo-Arabic|judéo-arabe
kaa|||Kara-Kalpak|karakalpak
kab|||Kabyle|kabyle
kac|||Kachin; Jingpho|kachin; jingpho
kal||kl|Kalaallisut; Greenlandic|groenlandais
kam|||Kamba|kamba
kan||kn|Kannada|kannada
kar|||Karen languages|karen, langues
kas||ks|Kashmiri|kashmiri
kau||kr|Kanuri|kanouri
kaw|||Kawi|kawi
kaz||kk|Kazakh|kazakh
kbd|||Kabardian|kabardien
kha|||Khasi|khasi
khi|||Khoisan (Other)|khoisan, autres langues
khm||km|Central Khmer|khmer central
kho|||Khotanese|khotanais
kik||ki|Kikuyu; Gikuyu|kikuyu
kin||rw|Kinyarwanda|rwanda
kir||ky|Kirghiz; Kyrgyz|kirghiz
kmb|||Kimbundu|kimbundu
kok|||Konkani|konkani
kom||kv|Komi|kom
kon||kg|Kongo|kongo
kor||ko|Korean|coréen
kos|||Kosraean|kosrae
kpe|||Kpelle|kpellé
krc|||Karachay-Balkar|karatchai balkar
krl|||Karelian|carélien
kro|||Kru languages|krou, langues
kru|||Kurukh|kurukh
kua||kj|Kuanyama; Kwanyama|kuanyama; kwanyama
kum|||Kumyk|koumyk
kur||ku|Kurdish|kurde
kut|||Kutenai|kutenai
lad|||Ladino|judéo-espagnol
lah|||Lahnda|lahnda
lam|||Lamba|lamba
lao||lo|Lao|lao
lat||la|Latin|latin
lav||lv|Latvian|letton
lez|||Lezghian|lezghien
lim||li|Limburgan; Limburger; Limburgish|limbourgeois
lin||ln|Lingala|lingala
lit||lt|Lithuanian|lituanien
lol|||Mongo|mongo
loz|||Lozi|lozi
ltz||lb|Luxembourgish; Letzeburgesch|luxembourgeois
lua|||Luba-Lulua|luba-lulua
lub||lu|Luba-Katanga|luba-katanga
lug||lg|Ganda|ganda
lui|||Luiseno|luiseno
lun|||Lunda|lunda
luo|||Luo (Kenya and Tanzania)|luo (Kenya et Tanzanie)
lus|||Lushai|lushai
mac|mkd|mk|Macedonian|macédonien
mad|||Madurese|madourais
mag|||Magahi|magahi
mah||mh|Marshallese|marshall
mai|||Maithili|maithili
mak|||Makasar|makassar
mal||ml|Malayalam|malayalam
man|||Mandingo|mandingue
mao|mri|mi|Maori|maori
map|||Austronesian (Other)|malayo-polynésiennes, autres langues
mar||mr|Marathi|marathe
mas|||Masai|massaï
may|msa|ms|Malay|malais
mdf|||Moksha|moksa
mdr|||Mandar|mandar
men|||Mende|mendé
mga|||Irish, Middle (900-1200)|irlandais moyen (900-1200)
mic|||Mi'kmaq; Micmac|mi'kmaq; micmac
min|||Minangkabau|minangkabau
mis|||Uncoded languages|langues non codées
mkh|||Mon-Khmer (Other)|môn-khmer, autres langues
mlg||mg|Malagasy|malgache
mlt||mt|Maltese|maltais
mnc|||Manchu|mandchou
mni|||Manipuri|manipuri
mno|||Manobo languages|manobo, langues
moh|||Mohawk|mohawk
mol||mo|Moldavian|moldave
mon||mn|Mongolian|mongol
mos|||Mossi|moré
mul|||Multiple languages|multilingue
mun|||Munda languages|mounda, langues
mus|||Creek|muskogee
mwl|||Mirandese|mirandais
mwr|||Marwari|marvari
myn|||Mayan languages|maya, langues
myv|||Erzya|erza
nah|||Nahuatl languages|nahuatl, langues
nai|||North American Indian|indiennes d'Amérique du Nord, autres langues
nap|||Neapolitan|napolitain
nau||na|Nauru|nauruan
nav||nv|Navajo; Navaho|navaho
nbl||nr|Ndebele, South; South Ndebele|ndébélé du Sud
nde||nd|Ndebele, North; North Ndebele|ndébélé du Nord
ndo||ng|Ndonga|ndonga
nds|||Low German; Low Saxon; German, Low; Saxon, Low|bas allemand; bas saxon; allemand, bas; saxon, bas
nep||ne|Nepali|népalais
new|||Nepal Bhasa; Newari|nepal bhasa; newari
nia|||Nias|nias
nic|||Niger-Kordofanian (Other)|nigéro-congolaises, autres langues
niu|||Niuean|niué
nno||nn|Norwegian Nynorsk; Nynorsk, Norwegian|norvégien nynorsk; nynorsk, norvégien
nob||nb|Bokmål, Norwegian; Norwegian Bokmål|norvégien bokmål
nog|||Nogai|nogaï; nogay
non|||Norse, Old|norrois, vieux
nor||no|Norwegian|norvégien
nqo|||N'Ko|n'ko
nso|||Pedi; Sepedi; Northern Sotho|pedi; sepedi; sotho du Nord
nub|||Nubian languages|nubiennes, langues
nwc|||Classical Newari; Old Newari; Classical Nepal Bhasa|newari classique
nya||ny|Chichewa; Chewa; Nyanja|chichewa; chewa; nyanja
nym|||Nyamwezi|nyamwezi
nyn|||Nyankole|nyankolé
nyo|||Nyoro|nyoro
nzi|||Nzima|nzema
oci||oc|Occitan (post 1500); Provençal|occitan (après 1500); provençal
oji||oj|Ojibwa|ojibwa
ori||or|Oriya|oriya
orm||om|Oromo|galla
osa|||Osage|osage
oss||os|Ossetian; Ossetic|ossète
ota|||Turkish, Ottoman (1500-1928)|turc ottoman (1500-1928)
oto|||Otomian languages|otomangue, langues
paa|||Papuan (Other)|papoues, autres langues
pag|||Pangasinan|pangasinan
pal|||Pahlavi|pahlavi
pam|||Pampanga; Kapampangan|pampangan
pan||pa|Panjabi; Punjabi|pendjabi
pap|||Papiamento|papiamento
pau|||Palauan|palau
peo|||Persian, Old (ca.600-400 B.C.)|perse, vieux (ca. 600-400 av. J.-C.)
per|fas|fa|Persian|persan
phi|||Philippine (Other)|philippines, autres langues
phn|||Phoenician|phénicien
pli||pi|Pali|pali
pol||pl|Polish|polonais
pon|||Pohnpeian|pohnpei
por||pt|Portuguese|portugais
pra|||Prakrit languages|prâkrit
pro|||Provençal, Old (to 1500)|provençal ancien (jusqu'à 1500)
pus||ps|Pushto; Pashto|pachto
qaa-qtz|||Reserved for local use|réservée à l'usage local
que||qu|Quechua|quechua
raj|||Rajasthani|rajasthani
rap|||Rapanui|rapanui
rar|||Rarotongan; Cook Islands Maori|rarotonga; maori des îles Cook
roa|||Romance (Other)|romanes, autres langues
roh||rm|Romansh|romanche
rom|||Romany|tsigane
rum|ron|ro|Romanian|roumain
run||rn|Rundi|rundi
rup|||Aromanian; Arumanian; Macedo-Romanian|aroumain; macédo-roumain
rus||ru|Russian|russe
sad|||Sandawe|sandawe
sag||sg|Sango|sango
sah|||Yakut|iakoute
sai|||South American Indian (Other)|indiennes d'Amérique du Sud, autres langues
sal|||Salishan languages|salish, langues
sam|||Samaritan Aramaic|samaritain
san||sa|Sanskrit|sanskrit
sas|||Sasak|sasak
sat|||Santali|santal
scc|srp|sr|Serbian|serbe
scn|||Sicilian|sicilien
sco|||Scots|écossais
scr|hrv|hr|Croatian|croate
sel|||Selkup|selkoupe
sem|||Semitic (Other)|sémitiques, autres langues
sga|||Irish, Old (to 900)|irlandais ancien (jusqu'à 900)
sgn|||Sign Languages|langues des signes
shn|||Shan|chan
sid|||Sidamo|sidamo
sin||si|Sinhala; Sinhalese|singhalais
sio|||Siouan languages|sioux, langues
sit|||Sino-Tibetan (Other)|sino-tibétaines, autres langues
sla|||Slavic (Other)|slaves, autres langues
slo|slk|sk|Slovak|slovaque
slv||sl|Slovenian|slovène
sma|||Southern Sami|sami du Sud
sme||se|Northern Sami|sami du Nord
smi|||Sami languages (Other)|sami, autres langues
smj|||Lule Sami|sami de Lule
smn|||Inari Sami|sami d'Inari
smo||sm|Samoan|samoan
sms|||Skolt Sami|sami skolt
sna||sn|Shona|shona
snd||sd|Sindhi|sindhi
snk|||Soninke|soninké
sog|||Sogdian|sogdien
som||so|Somali|somali
son|||Songhai languages|songhai, langues
sot||st|Sotho, Southern|sotho du Sud
spa||es|Spanish; Castilian|espagnol; castillan
srd||sc|Sardinian|sarde
srn|||Sranan Tongo|sranan tongo
srr|||Serer|sérère
ssa|||Nilo-Saharan (Other)|nilo-sahariennes, autres langues
ssw||ss|Swati|swati
suk|||Sukuma|sukuma
sun||su|Sundanese|soundanais
sus|||Susu|soussou
sux|||Sumerian|sumérien
swa||sw|Swahili|swahili
swe||sv|Swedish|suédois
syc|||Classical Syriac|syriaque classique
syr|||Syriac|syriaque
tah||ty|Tahitian|tahitien
tai|||Tai (Other)|thaïes, autres langues
tam||ta|Tamil|tamoul
tat||tt|Tatar|tatar
tel||te|Telugu|télougou
tem|||Timne|temne
ter|||Tereno|tereno
tet|||Tetum|tetum
tgk||tg|Tajik|tadjik
tgl||tl|Tagalog|tagalog
tha||th|Thai|thaï
tib|bod|bo|Tibetan|tibétain
tig|||Tigre|tigré
tir||ti|Tigrinya|tigrigna
tiv|||Tiv|tiv
tkl|||Tokelau|tokelau
tlh|||Klingon; tlhIngan-Hol|klingon
tli|||Tlingit|tlingit
tmh|||Tamashek|tamacheq
tog|||Tonga (Nyasa)|tonga (Nyasa)
ton||to|Tonga (Tonga Islands)|tongan (Îles Tonga)
tpi|||Tok Pisin|tok pisin
tsi|||Tsimshian|tsimshian
tsn||tn|Tswana|tswana
tso||ts|Tsonga|tsonga
tuk||tk|Turkmen|turkmène
tum|||Tumbuka|tumbuka
tup|||Tupi languages|tupi, langues
tur||tr|Turkish|turc
tut|||Altaic (Other)|altaïques, autres langues
tvl|||Tuvalu|tuvalu
twi||tw|Twi|twi
tyv|||Tuvinian|touva
udm|||Udmurt|oudmourte
uga|||Ugaritic|ougaritique
uig||ug|Uighur; Uyghur|ouïgour
ukr||uk|Ukrainian|ukrainien
umb|||Umbundu|umbundu
und|||Undetermined|indéterminée
urd||ur|Urdu|ourdou
uzb||uz|Uzbek|ouszbek
vai|||Vai|vaï
ven||ve|Venda|venda
vie||vi|Vietnamese|vietnamien
vol||vo|Volapük|volapük
vot|||Votic|vote
wak|||Wakashan languages|wakashennes, langues
wal|||Walamo|walamo
war|||Waray|waray
was|||Washo|washo
wel|cym|cy|Welsh|gallois
wen|||Sorbian languages|sorabes, langues
wln||wa|Walloon|wallon
wol||wo|Wolof|wolof
xal|||Kalmyk; Oirat|kalmouk; oïrat
xho||xh|Xhosa|xhosa
yao|||Yao|yao
yap|||Yapese|yapois
yid||yi|Yiddish|yiddish
yor||yo|Yoruba|yoruba
ypk|||Yupik languages|yupik, langues
zap|||Zapotec|zapotèque
zbl|||Blissymbols; Blissymbolics; Bliss|symboles Bliss; Bliss
zen|||Zenaga|zenaga
zha||za|Zhuang; Chuang|zhuang; chuang
znd|||Zande languages|zandé, langues
zul||zu|Zulu|zoulou
zun|||Zuni|zuni
zxx|||No linguistic content|pas de contenu linguistique
zza|||Zaza; Dimili; Dimli; Kirdki; Kirmanjki; Zazaki|zaza; dimili; dimli; kirdki; kirmanjki; zazaki
