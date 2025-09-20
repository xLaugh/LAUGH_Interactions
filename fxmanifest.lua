fx_version 'cerulean'
lua54 'yes'
game  'gta5'
author 'xLaugh'
version '0.0.1'
 
client_scripts{
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
	'client/*.lua'
 
}

server_scripts{
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
	'server/*.lua'

}

shared_scripts {
	'@ox_lib/init.lua',
	'@es_extended/imports.lua', 
}