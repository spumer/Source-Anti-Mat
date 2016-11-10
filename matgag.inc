/** Double-include prevention */
#if defined _matgag_included_
  #endinput
#endif
#define _matgag_included_
 
public SharedPlugin:__pl_matgag = 
{
	name = "matgag",
	file = "mat_gag_0_3.smx",
	required = 0,
};
 
public __pl_matgag_SetNTVOptional()
{
	MarkNativeAsOptional("MatGag_Filter");
}
 
 
/**
 * Checking string with "mat" filter
 *
 * @param userid	Who type a message.
 * @param msg		Message.
 * @return			True if not hidden "mat" found, false - if chat for this player blocked.
 */
native bool:MatGag_Filter(userid, String:msg[], maxlen);