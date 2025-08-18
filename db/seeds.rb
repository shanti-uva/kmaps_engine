# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#

[ { name: 'Variant Spelling',  code: 'var.spell',     description: 'This refers to what is genuinely an accepted variant spelling, as opposed to a simple typo, carvo, or other accidental mispelling of a term.' },
  { name: 'Mistaken Spelling', code: 'mistake.spell', description: "This is when a term has simply been mispelled. We want to catalog so that people can understand its correct spelling, but we also want to be clear that as far as we understand, this is a typo or carvo or the product of a writer who doesn't know how to spell a word, rather than  a well attested alternative spelling. Of course if enough people \"mispell\" a word, it does become a \"genuine\" alternative spelling..." },
  { name: 'Acronym',           code: 'acro.spell',    description: 'This is used when a term is an acronym of another place name, such as TAR for the Tibet Autonomous Region.' },
  { name: 'Contraction',       code: 'contract'},
  { name: 'Expansion',         code: 'expform'}
].each{|a| AltSpellingSystem.update_or_create(a)}

[ { name: 'Official', code: 'official'}, {name: 'Popular', code: 'popular'}].each{|a| FeatureNameType.update_or_create(a)}

[ { is_symmetric: true,  label: 'is related to', asymmetric_label: 'is related to', code: 'is.related.to', is_hierarchical: false},
].each{|a| FeatureRelationType.update_or_create(a)}

[ { name: 'Urdu',       code: 'urd'},
  { name: 'English',    code: 'eng'},
  { name: 'Tibetan',    code: 'bod'},
  { name: 'Nepali',     code: 'nep'},
  { name: 'Dzongkha',   code: 'dzo'},
  { name: 'Chinese',    code: 'zho'},
  { name: 'Mongolian',  code: 'mon'},
  { name: 'French',     code: 'fre'},
  { name: 'German',     code: 'deu'},
  { name: 'Hindi',      code: 'hin'},
  { name: 'Unknown',    code: 'unk'},
  { name: 'Arabic',     code: 'ara'},
  { name: 'Burmese',    code: 'mya'},
  { name: 'Italian',    code: 'ita'},
  { name: 'Japanese',   code: 'jpn'},
  { name: 'Korean',     code: 'kor'},
  { name: 'Latin',      code: 'lat'},
  { name: 'Pali',       code: 'pli'},
  { name: 'Prakrit',    code: 'pra'},
  { name: 'Polish',     code: 'pol'},
  { name: 'Russian',    code: 'rus'},
  { name: 'Sanskrit',   code: 'san'},
  { name: 'Sinhalese ', code: 'sin'},
  { name: 'Spanish',    code: 'spa'},
  { name: 'Thai',       code: 'tha'}
].each{|a| Language.update_or_create(a)}

[ { code: 'indo.standard.translit',   name: 'Indological Standard Transliteration',              description: "<p>This is  for representing the spelling of Nepali, Hindi and Sanskrit words from the Devangari script in Latin script through the addition of special diacritic marks. Thus \"maṇḍala\" instead of \"mandala\".</p>" }, 
  { code: 'thl.ext.wyl.translit',     name: 'THL Extended Wylie Transliteration',                description: "<p>This is for representing the spelling of Tibetan words in Latin script.</p>" },
  { code: 'chi.wyl.translit',         name: 'Chinese Wylie Transliteration',                     description: "<p>This is a system used only in China for transliterating Tibetan in roman script. It is very close to wylie, but, for example, uses a v instead of an ' for the a chung.</p>" },
  { code: 'acip.tib.translit',        name: 'ACIP Tibetan Transliteration',                      description: "<p>This is the transliteration system for Tibetan used by the Asian Classics Input Project for their monastic text input of Buddhist scriptures in India. It is similar to Wylie but with a number of key differences.</p>" },
  { code: 'unident.tib.translit',     name: 'Unidentified System of Tibetan Transliteration',    description: "<p>This is used for any transliteration system used for Tibetan which is unknown. It may be a system not yet identified, or it might be just a popular rendering of the specific toponym in question without any underlying system behind it.</p>" },
  { code: 'unident.mon.translit',     name: 'Unidentified System of Mongolian Transliteration',  description: "<p>This is used for any transliteration system used for Mongolian which is unknown. It may be a system not yet identified, or it might be just a popular rendering of the specific toponym in question without any underlying system behind it.</p>" },
  { code: 'unident.nep.translit',     name: 'Unidentified System of Nepali Transliteration',     description: "<p>This is used for any transliteration system used for Nepali which is unknown. It may be a system not yet identified, or it might be just a popular rendering of the specific toponym in question without any underlying system behind it.</p>" },
  { code: 'unident.chi.translit',     name: 'Unidentified System of Chinese Transliteration',    description: "<p>This is used for any transliteration system used for Chinese which is unknown. It may be a system not yet identified, or it might be just a popular rendering of the specific toponym in question without any underlying system behind it.</p>" },
  { code: 'unident.dzo.translit',     name: 'Unidentified System of Dzongkha Transliteration',   description: "<p>This is used for any transliteration system used for Dzongkha which is unknown. It may be a system not yet identified, or it might be just a popular rendering of the specific toponym in question without any underlying system behind it.</p>" },
  { code: 'trad.to.simp.ch.translit', name: 'Traditional-to-Simplified Chinese Transliteration', description: "<p>This is the system used to create simplified Chinese characters renderings of Chinese terms in traditional Chinese characters.</p>" },
  { code: 'gen.wyl.tib.translit',     name: 'General Wylie System of Tibetan Transliteration',   description: "<p>This is used only for systems of Wylie that vary from the THL Extended Wylie system in their transliteration of Tibetan in Latin script.</p>" },
  { code: 'loc.tib.translit',         name: 'Library of Congress Tibetan Transliteration',       description: "<p>This is the transliteration system used by the US Library of Congress for Tibetan.</p>" },
  { code: 'thl.mongol.translit',      name: 'THL Mongolian Script Simplified Transliteration' },
  { code: 'vm.mongol.translit',       name: 'Vladimirtsov-Mostaert  Mongolian Vertical Script Transliteration' },
  { code: 'loc.mongol.translit',      name: 'Library of Congress Mongolian Vertical Script Transliteration' },
  { code: 'loc.cyr.mongol.translit',  name: 'Library of Congress Cyrillic Mongolian to Latin Transliteration' },
  { code: 'thl.cyr.mongol.translit',  name: 'THL Mongolian-Cyrillic Transliteration' },
  { code: 'san.to.tib.translit',      name: 'Sanskrit-to-Tibetan Transliteration' }
].each{|a| OrthographicSystem.update_or_create(a)}

[ { code: 'thl.simple.transcrip',        name: 'THL Simplified Tibetan Transcription',            description: "<p>This is for representing the sound of the Tibetan words in Latin Script in very simplified if imprecise fashion.</p>" },
  { code: 'chi.to.tib.script.transcrip', name: 'Chinese-to-Tibetan Transcription',                description: "<p>This is for representing the sound of Chinese words in Tibetan script.</p>" },
  { code: 'tib.to.chi.transcrip',        name: 'Tibetan-to-Chinese Transcription',                description: "<p>This is for representing the sound of Tibetan words in traditional or simplified Chinese characters.</p>" },
  { code: 'pinyin.transcrip',            name: 'Pinyin Transcription',                            description: "<p>This is for representing the sound of Chinese characters in Latin script. It can be shown with or without tones; if shown with tones, it uses special diacritic marks.</p>" },
  { code: 'ind.transcrip',               name: 'Indological Standard Transcription',              description: "<p>This is for representing the sound of Nepali, Hindi and Sanskrit words in Latin script without special diacritic marks.</p>" },
  { code: 'ipa.transcrip',               name: 'International Phonetic Alphabet Transcription',   description: "<p>The International Phonetic Alphabet (IPA) is a system of phonetic notation based on the Latin alphabet, devised by the International Phonetic Association as a standardized representation of the sounds of spoken language. It is a highly technical system primarily used by specialists, such as linguists, speech pathologists and therapists, foreign language teachers,  singers, actors, lexicographers, and translators.</p>" },
  { code: 'ethnic.pinyin.tib.transcrip', name: 'Ethnic Pinyin Tibetan Transcription',             description: "<p>This is a system used in contemporary China to represent Tibetan language in Latin script when it is felt that the ordinary Pinyin of the Chinese characters version of the Tibetan is too divergent from how the Tibetan is actually pronounced.</p>" },
  { code: 'eng.to.chi.char.transcrip',   name: 'English-to-Chinese Transcription',                description: "<p>This is a system used to render English language names in Chinese characters, whether they be simplified or traditional.</p>" },
  { code: 'hop.tib.transcrip',           name: 'Hopkins System of Tibetan Transcription',         description: "<p>This is Jeffrey Hopkins' system for representing the sound of Tibetan words in Latin script.</p>" },
  { code: 'kap.tib.transcrip',           name: 'Kapstein System of Tibetan Transcription',        description: "<p>This is Matthew Kapstein's system for representing the sound of Tibetan words in Latin script.</p>" },
  { code: 'unident.dzo.transcrip',       name: 'Unidentified System of Dzongkha Transcription',   description: "<p>This is used for any transcription system used for Dzongkha which is unknown. It may be a system not yet identified, or it might be just a popular rendering of the specific toponym in question without any underlying system behind it.</p>" },
  { code: 'unident.nep.transcrip',       name: 'Unidentified System of Nepali Transcription',     description: "<p>This is used for any transcription system used for Nepali which is unknown. It may be a system not yet identified, or it might be just a popular rendering of the specific toponym in question without any underlying system behind it.</p>" },
  { code: 'unident.chi.transcrip',       name: 'Unidentified System of Chinese Transcription',    description: "<p>This is used for any transcription system used for Chinese which is unknown. It may be a system not yet identified, or it might be just a popular rendering of the specific toponym in question without any underlying system behind it.</p>" },
  { code: 'unident.mon.transcrip',       name: 'Unidentified System of Mongolian Transcription',  description: "<p>This is used for any transcription system used for Mongolian which is unknown. It may be a system not yet identified, or it might be just a popular rendering of the specific toponym in question without any underlying system behind it.</p>" },
  { code: 'eng.to.tib.script.transcrip', name: 'English-to-Tibetan Transcription',                description: "<p>This is for representing the sound of English words in Tibetans script.</p>" },
  { code: 'unident.tib.transcrip',       name: 'Unidentified System of Tibetan Transcription',    description: "<p>This is used for any transcription system used for Tibetan which is unknown. It may be a system not yet identified, or it might be just a popular rendering of the specific toponym in question without any underlying system behind it.</p>" },
  { code: 'chan.tib.transcrip',          name: 'Chan System of Tibetan Transcription',            description: "<p>This is the system used by Victor Chan to transcribe Tibetan in his book Tibet Handbook</p>" },
  { code: 'dzo.transcrip',               name: 'Dzongkha Transcription' },
  { code: 'wade.giles.transcrip',        name: 'Wade-Giles Transcription' },
  { code: 'amdo.transcrip',              name: 'Amdo Transcription' },
  { code: 'mon.to.chi.transcrip',        name: 'Mongolian-to-Chinese Transcription' }
].each{|a| PhoneticSystem.update_or_create(a)}

person = AuthenticatedSystem::Person.find_by(fullname: 'Kmaps Admin')
person = AuthenticatedSystem::Person.create(fullname: 'Kmaps Admin') if person.nil?
a = { login: 'kmaps_admin', password: 'kmaps2013', password_confirmation: 'kmaps2013', email: 'root@' }
u = AuthenticatedSystem::User.find_by(login: a[:login])
if u.nil?
  u = person.create_user(a)
else
  u.update(a)
end

role = AuthenticatedSystem::Role.find_by(title: 'System Administrator')
role = AuthenticatedSystem::Role.create(title: 'System Administrator') if role.nil?
users = role.users
users << u if !users.include? u

p = role.permissions.find_by(title: 'authenticated_system/roles/index')
p = role.permissions.create(title: 'authenticated_system/roles/index') if p.nil?
p = role.permissions.find_by(title: 'authenticated_system/roles/show')
p = role.permissions.create(title: 'authenticated_system/roles/show') if p.nil?
p = role.permissions.find_by(title: 'authenticated_system/roles/edit')
p = role.permissions.create(title: 'authenticated_system/roles/edit') if p.nil?
p = role.permissions.find_by(title: 'authenticated_system/roles/update')
p = role.permissions.create(title: 'authenticated_system/roles/update') if p.nil?
p = role.permissions.find_by(title: 'admin/default/index')
p = role.permissions.create(title: 'admin/default/index') if p.nil?

[ { name: 'Dzongkha', :code => 'dzongkha'},
  { name: 'Devanagari script',              code: 'deva' },
  { name: 'Tibetan script',                 code: 'tibt' },
  { name: 'Cyrillic',                       code: 'cyrl' },
  { name: 'Simplified Chinese Characters',  code: 'hans' },
  { name: 'Traditional Chinese Characters', code: 'hant' },
  { name: 'Latin script',                   code: 'latin' }
].each{|a| WritingSystem.update_or_create(a)}

Blurb.create(code: 'homepage.intro') if Blurb.find_by(code: 'homepage.intro').nil?
