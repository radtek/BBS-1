﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Collections;

namespace BudCopyListen.Common
{
    public class CreateBAT
    {
        /// <summary> 
        /// ファイルのパス
        /// </summary> 
        private string _filepath;

        /// <summary> 
        /// 書き込むのIO
        /// </summary> 
        private StreamWriter fWriter = null;

        /// <summary> 
        /// ファイルのパス
        /// </summary> 
        public string FilePath
        {
            get { return _filepath; }
            set { _filepath = value; }
        }

                /// <summary> 
        /// ファイルを呼んでArrayListに保存して、行番号によって並べる
        /// </summary> 
        /// <param   name= "FilePath "> </param> 
        public CreateBAT(string FilePath)
        {
            _filepath = FilePath;
            FileInfo fileInfo = new FileInfo(_filepath);
            if (fileInfo.Exists)
            {
                File.Delete(_filepath);
            }
            else
            {
                if (!Directory.Exists(fileInfo.DirectoryName))
                {
                    Directory.CreateDirectory(fileInfo.DirectoryName);
                }
            }
            // ファイル新規
            FileStream fs = File.Create(_filepath);
            //fWriter = new StreamWriter(fs, Encoding.GetEncoding("utf-8"));
            fWriter = new StreamWriter(fs, Encoding.UTF8);
        }

        /// <summary> 
        /// BATファイル作成
        /// </summary> 
        /// <param name= "ノード">copycommand</param>
        /// <returns></returns> 
        public void Write(string copycommand)
        {
            StringBuilder sb = new StringBuilder();
            sb.Append("@echo off");
            sb.Append("\r\n");
            sb.Append(copycommand);
            fWriter.Write(sb.ToString() + "\r\n");
            // I/O close
            fWriter.Flush();
            fWriter.Dispose();
            fWriter.Close();
        }
    }
}
