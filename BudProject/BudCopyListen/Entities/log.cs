using System;
using System.Collections.Generic;

namespace BudCopyListen.Entities
{
	public class log
	{
		public int id { get; set; }
		public int monitorServerID { get; set; }
		public string monitorFileName { get; set; }
		public string monitorFilePath { get; set; }
		public string monitorFileType { get; set; }
		public string monitorFileSize { get; set; }
		public System.DateTime monitorTime { get; set; }
		public short transferFlg { get; set; }
		public int backupServerGroupID { get; set; }
		public int backupServerID { get; set; }
		public string backupServerFileName { get; set; }
		public string backupServerFilePath { get; set; }
		public string backupServerFileType { get; set; }
		public string backupServerFileSize { get; set; }
		public System.DateTime backupStartTime { get; set; }
		public System.DateTime backupEndTime { get; set; }
		public string backupTime { get; set; }
		public short backupFlg { get; set; }
		public System.DateTime copyStartTime { get; set; }
		public System.DateTime copyEndTime { get; set; }
		public string copyTime { get; set; }
		public short copyFlg { get; set; }
		public short deleteFlg { get; set; }
		public string deleter { get; set; }
		public System.DateTime deleteDate { get; set; }
		public string creater { get; set; }
		public System.DateTime createDate { get; set; }
		public string updater { get; set; }
		public System.DateTime updateDate { get; set; }
		public string restorer { get; set; }
		public System.DateTime restoreDate { get; set; }
		public string monitorFileStatus { get; set; }
		public Nullable<short> synchronismFlg { get; set; }
	}
}

