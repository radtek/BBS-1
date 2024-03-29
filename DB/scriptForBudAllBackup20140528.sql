USE [master]
GO
/****** Object:  Database [BudAllBackup]    Script Date: 2014/05/28 14:44:49 ******/
CREATE DATABASE [BudAllBackup]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'BudAllBackup', FILENAME = N'C:\WorkSpace\dabase\BudAllBackup.mdf' , SIZE = 13312KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'BudAllBackup_log', FILENAME = N'C:\WorkSpace\dabase\BudAllBackup_log.ldf' , SIZE = 63424KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [BudAllBackup] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [BudAllBackup].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [BudAllBackup] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [BudAllBackup] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [BudAllBackup] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [BudAllBackup] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [BudAllBackup] SET ARITHABORT OFF 
GO
ALTER DATABASE [BudAllBackup] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [BudAllBackup] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [BudAllBackup] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [BudAllBackup] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [BudAllBackup] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [BudAllBackup] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [BudAllBackup] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [BudAllBackup] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [BudAllBackup] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [BudAllBackup] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [BudAllBackup] SET  DISABLE_BROKER 
GO
ALTER DATABASE [BudAllBackup] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [BudAllBackup] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [BudAllBackup] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [BudAllBackup] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [BudAllBackup] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [BudAllBackup] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [BudAllBackup] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [BudAllBackup] SET RECOVERY FULL 
GO
ALTER DATABASE [BudAllBackup] SET  MULTI_USER 
GO
ALTER DATABASE [BudAllBackup] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [BudAllBackup] SET DB_CHAINING OFF 
GO
ALTER DATABASE [BudAllBackup] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [BudAllBackup] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'BudAllBackup', N'ON'
GO
USE [BudAllBackup]
GO
/****** Object:  User [peech]    Script Date: 2014/05/28 14:44:49 ******/
CREATE USER [peech] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetTranferList]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Batch submitted through debugger: SQLQuery32.sql|7|0|C:\Users\Administrator\AppData\Local\Temp\~vsA3E6.sql
-- Batch submitted through debugger: SQLQuery16.sql|7|0|C:\Users\Administrator\AppData\Local\Temp\~vsBC8E.sql
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--//@disPlayFlg 0:リアルタイム表示; 1:ファイル表示
--@TranferFlg 0:転送中-完了両方;　1:転送中のみ
--@StateFlg 0:OK-NG両方;1:NGのみ
--@LogFlg 0:ログ;1:容量
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetTranferList]( @groupId int=0,
	@StartDate datetime=null,@endDate datetime=null,
	@StartTime varchar(20)=null,@endTime varchar(20)=null,
	@TranferFlg int =0,@StateFlg int = 0,
	@LogFlg int = 0,@backupServerFileName VARCHAR(100)=null
	-- Add the parameters for the stored procedure here
	)
AS
begin
	-- set NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	set NOCOUNT ON;

    -- Insert statements for procedure here
    if object_id('tempdb.dbo.#TranferList') is not null     drop table #TranferList
    if object_id('tempdb.dbo.#tempLog') is not null     drop table #tempLog
    --転送容量表示用の臨時表
    create table #TranferList
    (
    transferDate datetime,
    transferTime int,
    transferFileCount int,
    transferFileSize bigint
    )
    --ログ表示用の臨時表
    create table #tempLog
    (
    [id] int,
	[monitorServerID] int  ,
	[monitorFileName] nvarchar(255)  ,
	[monitorFilePath] nvarchar(255)  ,
	[monitorFileType] nvarchar(255)  ,
	[monitorFileSize] nvarchar(255)  ,
	[monitorTime] datetime  ,
	[transferFlg] smallint  ,
	[backupServerGroupID] int NULL ,
	[backupServerID] int NULL ,
	[backupServerFileName] nvarchar(50)  ,
	[backupServerFilePath] nvarchar(50)  ,
	[backupServerFileType] nvarchar(50)  ,
	[backupServerFileSize] nvarchar(50)  ,
	[backupStartTime] datetime  ,
	[backupendTime] datetime  ,
	[backupTime] nvarchar(50)  ,
	[backupFlg] smallint  ,
	[copyStartTime] datetime  ,
	[copyendTime] datetime  ,
	[copyTime] nvarchar(255) NULL ,
	[copyFlg] smallint  ,
	[deleteFlg] smallint  ,
	[deleter] nvarchar(255) NULL ,
	[deleteDate] datetime NULL ,
	[creater] nvarchar(255)  ,
	[createDate] datetime  ,
	[updater] nvarchar(255)  ,
	[updateDate] datetime  ,
	[restorer] nvarchar(255) NULL ,
	[restoreDate] datetime NULL 
    )

    declare @sql  varchar(8000)
    declare @where varchar(8000)
    declare @start_date datetime
    declare @end_date datetime
    --set @sql = 'SELECT id, backupServerFileName,backupServerFileSize,copyStartTime,copyendTime,backupStartTime,backupendTime,backupTime,backupFlg FROM log '
    set @sql = 'SELECT id,monitorServerID  ,monitorFileName ,monitorFilePath ,monitorFileType ,' +
			'monitorFileSize ,monitorTime ,transferFlg ,backupServerGroupID ,backupServerID ,'+
			'backupServerFileName ,backupServerFilePath ,backupServerFileType ,backupServerFileSize ,'+
			'backupStartTime ,backupendTime ,backupTime ,backupFlg ,copyStartTime ,copyendTime ,'+
			'copyTime ,copyFlg  ,deleteFlg,deleter ,deleteDate ,creater ,createDate ,updater ,updateDate ,'+
			'restorer,restoreDate  FROM log '
    set @where = ' WHERE '
    
    IF(@TranferFlg = 0)
	begin
	--転送中-完了両方
		set @where = @where + ' transferFlg<>2 '  
	end
    ELSE
	begin
	 --転送中のみ
		set @where = @where + ' transferFlg=0 ' 
	end
	IF(@StateFlg != 0)
	begin
	--NGのみ
		set @where =@where + ' AND backupFlg=0 '  
	end
	IF(@groupId > 0)
	begin
	--グループID
		set @where = @where + ' AND backupServerGroupID=' + convert(varchar(10),@groupId)
	end
	IF(@backupServerFileName is not null and @backupServerFileName != '')
	begin
		set @where =@where + ' AND backupServerFileName like ''%' + @backupServerFileName + '%'''  
	end

	IF(@StartDate is null or @StartDate = '')
	begin
	--開始日付を入力しない場合
		declare @tempSql nvarchar(100)
		set @tempSql = 'SELECT @minDate=MIN(backupStartTime) FROM log ' + @where
		EXEC sp_executesql @tempSql,N'@minDate varchar(20) output',@StartDate output
		IF(@StartDate is null or @StartDate = '')
		begin
			set @StartDate = DATEADD(day,-30, GETDATE())
		end
		ELSE
		begin
			set @StartDate = CONVERT(varchar(10),@StartDate,120)
		end
	end
	IF(@endDate is null or @endDate='')
	begin
	--終了日付を入力しない場合
		set @endDate = GETDATE()
	end
	IF(@StartTime is null or @StartTime='')
	--開始時間を入力しない場合
	begin
		set @StartTime ='00:00:00'
	end
	IF(@endTime is null or @endTime='')
	begin
	--終了時間を入力しない場合
		set @endTime = '23:59:59'
	end
	declare @sumDays int
	declare @countDays int
	set @sumDays = DATEDIFF(day,@StartDate,@endDate)
	declare @varstart varchar(20)
	declare @varend varchar(20)
	declare @ORwhere varchar(8000)
	set @ORwhere = ''
	IF(@sumDays > 0)
	begin
		--開始日付と終了日付の条件
		WHILE(@sumDays >= 0)
		begin
		--終了日付>開始日付の場合
			set @varstart = CONVERT(varchar(10),DATEADD(day,-@sumDays,@endDate),120) +' '+ @StartTime
			set @varend = CONVERT(varchar(10),DATEADD(day,-@sumDays,@endDate),120) +' '+ @endTime;
			IF(@ORwhere = '')
			begin
				set @ORwhere = @ORwhere + ' (backupStartTime BETWEEN ''@varstart'' AND ''@varend'') '
			end
			ELSE
			begin
				set @ORwhere = @ORwhere + ' OR (backupStartTime BETWEEN ''@varstart'' AND ''@varend'')'
			end
			set @ORwhere = REPLACE(@ORwhere,'@varstart',@varstart)
			set @ORwhere = REPLACE(@ORwhere,'@varend',@varend)
			set @sumDays = @sumDays -1
		end
	end
	ELSE IF(@sumDays = 0)
	begin
		--終了日付＝開始日付の場合
		set @varstart = CONVERT(varchar(10),@StartDate,120) +' '+ @StartTime
		set @varend = CONVERT(varchar(10),@endDate,120) +' '+ @endTime;
		set @where = @where + 'AND backupStartTime BETWEEN ''@varstart'' AND ''@varend'' '
		set @where = REPLACE(@where,'@varstart',@varstart)
		set @where = REPLACE(@where,'@varend',@varend)
	end
	IF(@ORwhere !='')
	begin
		set @where = @where + ' AND (' + @ORwhere + ')'
	end
	--条件によって、検索データを臨時表にインサート
	insert into #tempLog(id,monitorServerID  ,monitorFileName ,monitorFilePath ,monitorFileType ,
	monitorFileSize ,monitorTime ,transferFlg ,backupServerGroupID ,backupServerID ,backupServerFileName ,
	backupServerFilePath ,backupServerFileType ,backupServerFileSize ,backupStartTime ,backupendTime ,
	backupTime ,backupFlg,copyStartTime ,copyendTime ,copyTime ,copyFlg  ,deleteFlg,deleter ,deleteDate ,
	creater ,createDate ,updater ,updateDate ,restorer,restoreDate 
	) exec(@sql + @where)
	
	IF (@LogFlg=0)
	begin
	--ログ表示の場合
		select * from #tempLog
	end
	ELSE
	begin
	--転送容量表示の場合
		declare @startHour int
		declare @endHour int
		declare @hourcount int
		set @startHour = DATEPART(HH,@StartTime)
		set @endHour = DATEPART(HH,@endTime)
		set @sumDays = DATEDIFF(day,@StartDate,@endDate)
		WHILE(@sumDays >= 0)
		begin
			set @hourcount = @endHour - @startHour
			WHILE(@hourcount >=0)
			begin
				insert into #TranferList(transferDate,transferTime,transferFileCount,transferFileSize)
				values(CONVERT(varchar(10),DATEADD(day,@sumDays,@StartDate),120),@endHour-@hourcount,0,0)
				set @hourcount = @hourcount -1
			end
			set @sumDays = @sumDays -1
		end
		--select * from #TranferList
		insert into #TranferList(transferDate,transferTime,transferFileCount,transferFileSize)
		SELECT CONVERT(varchar(10),backupStartTime,111),
		CASE DATEPART(HH,backupStartTime)
			WHEN '0' then '0'
			WHEN '1' then '1'
			WHEN '2' then '2'
			WHEN '3' then '3'
			WHEN '4' then '4'
			WHEN '5' then '5'
			WHEN '6' then '6'
			WHEN '7' then '7'
			WHEN '8' then '8'
			WHEN '9' then '9'
			WHEN '10' then '10'
			WHEN '11' then '11'
			WHEN '12' then '12'
			WHEN '13' then '13'
			WHEN '14' then '14'
			WHEN '15' then '15'
			WHEN '16' then '16'
			WHEN '17' then '17'
			WHEN '18' then '18'
			WHEN '19' then '19'
			WHEN '20' then '20'
			WHEN '21' then '21'
			WHEN '22' then '22'
			WHEN '23' then '23'
		end,
		CASE 
			WHEN backupServerFileName is not null THEN 1
			--WHEN backupServerFileName !='' THEN 1
			ELSE 0
		end,
		backupServerFileSize	
		FROM #tempLog
		SELECT convert(varchar(10),transferDate,111) AS 'transferDate',transferTime,sum(transferFileCount) AS 'transferFileCount',sum(transferFileSize) AS 'transferFileSize' FROM #TranferList
		GROUP BY transferDate,transferTime
		order by transferDate,transferTime
	end
	if object_id('tempdb.dbo.#TranferList') is not null     drop table #TranferList
	if object_id('tempdb.dbo.#tempLog') is not null     drop table #tempLog
	
end



GO
/****** Object:  StoredProcedure [dbo].[sp_GetTransferList2]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Batch submitted through debugger: SQLQuery36.sql|2|0|C:\Users\Administrator\AppData\Local\Temp\~vs3F33.sql
/****** Object:  StoredProcedure [dbo].[sp_GetTransferList2]    Script Date: 04/04/2014 16:18:28 ******/

-- Batch submitted through debugger: SQLQuery31.sql|7|0|C:\Users\Administrator\AppData\Local\Temp\~vs42C.sql
-- Batch submitted through debugger: SQLQuery16.sql|7|0|C:\Users\Administrator\AppData\Local\Temp\~vsBC8E.sql
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--//@disPlayFlg 0:リアルタイム表示; 1:ファイル表示
--@TranferFlg 0:転送中-完了両方;　1:転送中のみ
--@StateFlg 0:OK-NG両方;1:NGのみ
--@LogFlg 0:ログ;1:容量
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetTransferList2]( @groupId int=0,
	@StartDate datetime=null,@endDate datetime=null,
	@StartTime varchar(20)=null,@endTime varchar(20)=null,
	@TranferFlg int =0,@StateFlg int = 0,
	@LogFlg int = 0,@backupServerFileName VARCHAR(100)=null,
	@Pindex int = 1,@Psize int = 20
	-- Add the parameters for the stored procedure here
	)
AS
begin
	-- set NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	set NOCOUNT ON;

    -- Insert statements for procedure here
    if object_id('tempdb.dbo.#TranferList') is not null     drop table #TranferList
    if object_id('tempdb.dbo.#tempLog') is not null     drop table #tempLog
    if object_id('tempdb.dbo.#tempCount') is not null     drop table #tempCount
    --転送容量表示用の臨時表
    create table #TranferList
    (
    transferDate datetime,
    transferTime int,
    transferFileCount int,
    transferFileSize bigint,
    )
    --ログ表示用の臨時表
    create table #tempLog
    (
    [id] int,
	[monitorServerID] int  ,
	[monitorFileName] nvarchar(255)  ,
	[monitorFilePath] nvarchar(255)  ,
	[monitorFileType] nvarchar(255)  ,
	[monitorFileSize] nvarchar(255)  ,
	[monitorTime] datetime  ,
	[transferFlg] smallint  ,
	[backupServerGroupID] int NULL ,
	[backupServerID] int NULL ,
	[backupServerFileName] nvarchar(50)  ,
	[backupServerFilePath] nvarchar(50)  ,
	[backupServerFileType] nvarchar(50)  ,
	[backupServerFileSize] nvarchar(50)  ,
	[backupStartTime] datetime  ,
	[backupendTime] datetime  ,
	[backupTime] nvarchar(50)  ,
	[backupFlg] smallint  ,
	[copyStartTime] datetime  ,
	[copyendTime] datetime  ,
	[copyTime] nvarchar(255) NULL ,
	[copyFlg] smallint  ,
	[deleteFlg] smallint  ,
	[deleter] nvarchar(255) NULL ,
	[deleteDate] datetime NULL ,
	[creater] nvarchar(255)  ,
	[createDate] datetime  ,
	[updater] nvarchar(255)  ,
	[updateDate] datetime  ,
	[restorer] nvarchar(255) NULL ,
	[restoreDate] datetime NULL,
	[monitorFileStatus] text null,
	[row] int
    )
    create table #tempCount
    (
		[totalCount] int
    )

    declare @sql  varchar(8000)
    declare @sql_count varchar(8000)
    declare @where varchar(8000)
    declare @start_date datetime
    declare @end_date datetime
    declare @num_sql varchar(8000)
    declare @num_where varchar(8000)
    
    set @num_where = ' WHERE row > ' + Convert(varchar(10),((@Pindex-1) * @Psize)) + ' and row <= ' + Convert(varchar(10),(@Pindex * @Psize))
    
    --set @sql = 'SELECT id, backupServerFileName,backupServerFileSize,copyStartTime,copyendTime,backupStartTime,backupendTime,backupTime,backupFlg FROM log '
    set @sql = 'SELECT id,monitorServerID  ,monitorFileName ,monitorFilePath ,monitorFileType ,' +
			'monitorFileSize ,monitorTime ,transferFlg ,backupServerGroupID ,backupServerID ,'+
			'backupServerFileName ,backupServerFilePath ,backupServerFileType ,backupServerFileSize ,'+
			'backupStartTime ,backupendTime ,backupTime ,backupFlg ,copyStartTime ,copyendTime ,'+
			'copyTime ,copyFlg  ,deleteFlg,deleter ,deleteDate ,creater ,createDate ,updater ,updateDate ,'+
			'restorer,restoreDate,monitorFileStatus,ROW_NUMBER() over(order by createDate desc) as row  FROM log'
	
	set @where = ''
    set @where = @where + ' WHERE '
    
    --IF(@TranferFlg = 0)
	--begin
	--転送中-完了両方
		--set @where = @where + ' transferFlg<>2 '  
	--end
    --ELSE
	--begin
	 --転送中のみ
		--set @where = @where + ' transferFlg=0 ' 
	--end
	IF(@StateFlg = 2)
	begin
	--OK・NG両方
		set @where = @where + ' backupFlg<>2'  
	end
	ELSE
	begin
	 --OK・NGのみ
		set @where = @where + ' backupFlg=' + convert(varchar(10),@StateFlg)
	end
	IF(@groupId > 0)
	begin
	--グループID
		set @where = @where + ' AND backupServerGroupID=' + convert(varchar(10),@groupId)
	end
	IF(@backupServerFileName is not null and @backupServerFileName != '')
	begin
		set @where =@where + ' AND (backupServerFileName like ''%' + @backupServerFileName + '%'' OR backupServerFilePath like ''%' + @backupServerFileName + '%'') '  
		--set @where = @where + ' AND (backupServerFileName like ''%' + @backupServerFileName + '%'')'
	end
	--IF(@StartDate is null or @StartDate = '')
	--begin
	--開始日付を入力しない場合
		--declare @tempSql nvarchar(100)
		--set @tempSql = 'SELECT @minDate=MIN(backupStartTime) FROM log ' + @where
		--EXEC sp_executesql @tempSql,N'@minDate varchar(20) output',@StartDate output
		--IF(@StartDate is null or @StartDate = '')
		--begin
			--set @StartDate = DATEADD(day,-30, GETDATE())
		--end
		--ELSE
		--begin
			--set @StartDate = CONVERT(varchar(10),@StartDate,120)
		--end
	--end
	--IF(@endDate is null or @endDate='')
	--begin
	--終了日付を入力しない場合
		--set @endDate = GETDATE()
	--end
	IF(@StartTime is null or @StartTime='')
	--開始時間を入力しない場合
	begin
		set @StartTime ='00:00:00'
	end
	IF(@endTime is null or @endTime='')
	begin
	--終了時間を入力しない場合
		set @endTime = '23:59:59'
	end
	declare @sumDays int
	declare @countDays int
	set @sumDays = DATEDIFF(day,@StartDate,@endDate)
	declare @varstart varchar(20)
	declare @varend varchar(20)
	declare @ORwhere varchar(8000)
	set @ORwhere = ''
	IF(@sumDays > 0)
	begin
		--開始日付と終了日付の条件
		--WHILE(@sumDays >= 0)
		--begin
		--終了日付>開始日付の場合
			set @varstart = CONVERT(varchar(10),DATEADD(day,-@sumDays,@endDate),120) +' '+ @StartTime
			--set @varend = CONVERT(varchar(10),DATEADD(day,-@sumDays,@endDate),120) +' '+ @endTime;
			set @varend = CONVERT(varchar(10),@endDate,120) +' '+ @endTime;
			IF(@ORwhere = '')
			begin
				set @ORwhere = @ORwhere + ' (backupStartTime BETWEEN ''@varstart'' AND ''@varend'') '
			end
			ELSE
			begin
				set @ORwhere = @ORwhere + ' OR (backupStartTime BETWEEN ''@varstart'' AND ''@varend'') '
			end
			set @ORwhere = REPLACE(@ORwhere,'@varstart',@varstart)
			set @ORwhere = REPLACE(@ORwhere,'@varend',@varend)
			set @sumDays = @sumDays -1
		--end
	end
	ELSE IF(@sumDays = 0 AND @StartDate!='' AND @endDate!='')
	begin
		--終了日付＝開始日付の場合
		set @varstart = CONVERT(varchar(10),@StartDate,120) +' '+ @StartTime
		set @varend = CONVERT(varchar(10),@endDate,120) +' '+ @endTime;
		set @where = @where + 'AND backupStartTime BETWEEN ''@varstart'' AND ''@varend'' '
		set @where = REPLACE(@where,'@varstart',@varstart)
		set @where = REPLACE(@where,'@varend',@varend)
	end
	IF(@ORwhere !='')
	begin
		set @where = @where + ' AND (' + @ORwhere + ')'
	end		
	--条件によって、検索データを臨時表にインサート
	insert into #tempLog(id,monitorServerID  ,monitorFileName ,monitorFilePath ,monitorFileType ,
	monitorFileSize ,monitorTime ,transferFlg ,backupServerGroupID ,backupServerID ,backupServerFileName ,
	backupServerFilePath ,backupServerFileType ,backupServerFileSize ,backupStartTime ,backupendTime ,
	backupTime ,backupFlg,copyStartTime ,copyendTime ,copyTime ,copyFlg  ,deleteFlg,deleter ,deleteDate ,
	creater ,createDate ,updater ,updateDate ,restorer,restoreDate,monitorFileStatus,row
	) exec(@sql + @where)
	
	set @sql_count = 'SELECT COUNT(id) as totalCount FROM log ' + @where
	insert into #tempCount(totalCount) exec(@sql_count)
	
	IF (@LogFlg=0)
	begin
	--ログ表示の場合
		set @num_sql = 'select *,(select totalCount from #tempCount) as totalCount from #tempLog '
		exec(@num_sql + @num_where)
	end
	ELSE
	begin
	--転送容量表示の場合
		declare @startHour int
		declare @endHour int
		declare @hourcount int
		set @startHour = DATEPART(HH,@StartTime)
		set @endHour = DATEPART(HH,@endTime)
		set @sumDays = DATEDIFF(day,@StartDate,@endDate)
		WHILE(@sumDays >= 0)
		begin
			set @hourcount = @endHour - @startHour
			WHILE(@hourcount >=0)
			begin
				insert into #TranferList(transferDate,transferTime,transferFileCount,transferFileSize)
				values(CONVERT(varchar(10),DATEADD(day,@sumDays,@StartDate),120),@endHour-@hourcount,0,0)
				set @hourcount = @hourcount -1
			end
			set @sumDays = @sumDays -1
		end
		--select * from #TranferList
		insert into #TranferList(transferDate,transferTime,transferFileCount,transferFileSize)
		SELECT CONVERT(varchar(10),backupStartTime,111),
		CASE DATEPART(HH,backupStartTime)
			WHEN '0' then '0'
			WHEN '1' then '1'
			WHEN '2' then '2'
			WHEN '3' then '3'
			WHEN '4' then '4'
			WHEN '5' then '5'
			WHEN '6' then '6'
			WHEN '7' then '7'
			WHEN '8' then '8'
			WHEN '9' then '9'
			WHEN '10' then '10'
			WHEN '11' then '11'
			WHEN '12' then '12'
			WHEN '13' then '13'
			WHEN '14' then '14'
			WHEN '15' then '15'
			WHEN '16' then '16'
			WHEN '17' then '17'
			WHEN '18' then '18'
			WHEN '19' then '19'
			WHEN '20' then '20'
			WHEN '21' then '21'
			WHEN '22' then '22'
			WHEN '23' then '23'
		end,
		CASE 
			WHEN backupServerFileName is not null THEN 1
			--WHEN backupServerFileName !='' THEN 1
			ELSE 0
		end,
		backupServerFileSize	
		FROM #tempLog
		SELECT convert(varchar(10),transferDate,111) AS 'transferDate',transferTime,sum(transferFileCount) AS 'transferFileCount',sum(transferFileSize) AS 'transferFileSize' FROM #TranferList
		GROUP BY transferDate,transferTime
		order by transferDate,transferTime
	end
	if object_id('tempdb.dbo.#TranferList') is not null     drop table #TranferList
	if object_id('tempdb.dbo.#tempLog') is not null     drop table #tempLog
	
end



GO
/****** Object:  Table [dbo].[backupServer]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[backupServer](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DBServerIP] [nvarchar](40) NOT NULL,
	[backupServerName] [nvarchar](255) NOT NULL,
	[backupServerIP] [nvarchar](40) NOT NULL,
	[memo] [nvarchar](255) NOT NULL,
	[account] [nvarchar](255) NOT NULL,
	[password] [nvarchar](255) NOT NULL,
	[startFile] [nvarchar](255) NOT NULL,
	[ssbpath] [nvarchar](255) NOT NULL,
	[deleteFlg] [smallint] NOT NULL,
	[deleter] [nvarchar](255) NOT NULL,
	[deleteDate] [datetime] NOT NULL,
	[creater] [nvarchar](255) NOT NULL,
	[createDate] [datetime] NOT NULL,
	[updater] [nvarchar](255) NOT NULL,
	[updateDate] [datetime] NOT NULL,
	[restorer] [nvarchar](255) NOT NULL,
	[restoreDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[backupServerGroup]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[backupServerGroup](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DBServerIP] [nvarchar](40) NOT NULL,
	[backupServerGroupName] [nvarchar](255) NOT NULL,
	[monitorServerID] [int] NOT NULL,
	[memo] [nvarchar](255) NOT NULL,
	[deleteFlg] [smallint] NOT NULL,
	[deleter] [nvarchar](255) NOT NULL,
	[deleteDate] [datetime] NOT NULL,
	[creater] [nvarchar](255) NOT NULL,
	[createDate] [datetime] NOT NULL,
	[updater] [nvarchar](255) NOT NULL,
	[updateDate] [datetime] NOT NULL,
	[restorer] [nvarchar](255) NOT NULL,
	[restoreDate] [datetime] NOT NULL,
 CONSTRAINT [PK__backupSe__3213E83F07020F21] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[backupServerGroupDetail]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[backupServerGroupDetail](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DBServerIP] [nvarchar](40) NOT NULL,
	[backupServerGroupID] [int] NOT NULL,
	[backupServerID] [int] NOT NULL,
	[deleteFlg] [smallint] NOT NULL,
	[deleter] [nvarchar](255) NOT NULL,
	[deleteDate] [datetime] NOT NULL,
	[creater] [nvarchar](255) NOT NULL,
	[createDate] [datetime] NOT NULL,
	[updater] [nvarchar](255) NOT NULL,
	[updateDate] [datetime] NOT NULL,
	[restorer] [nvarchar](255) NOT NULL,
	[restoreDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[fileTypeSet]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fileTypeSet](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DBServerIP] [nvarchar](40) NOT NULL,
	[monitorServerFolderName] [nvarchar](255) NOT NULL,
	[monitorServerID] [int] NOT NULL,
	[exceptAttributeFlg1] [nvarchar](255) NOT NULL,
	[exceptAttribute1] [nvarchar](255) NOT NULL,
	[exceptAttributeFlg2] [nvarchar](255) NOT NULL,
	[exceptAttribute2] [nvarchar](255) NOT NULL,
	[exceptAttributeFlg3] [nvarchar](255) NOT NULL,
	[exceptAttribute3] [nvarchar](255) NOT NULL,
	[systemFileFlg] [smallint] NOT NULL,
	[hiddenFileFlg] [smallint] NOT NULL,
	[attribute1] [nvarchar](255) NOT NULL,
	[attribute2] [nvarchar](255) NOT NULL,
	[attribute3] [nvarchar](255) NOT NULL,
	[deleteFlg] [smallint] NOT NULL,
	[deleter] [nvarchar](255) NOT NULL,
	[deleteDate] [datetime] NOT NULL,
	[creater] [nvarchar](255) NOT NULL,
	[createDate] [datetime] NOT NULL,
	[updater] [nvarchar](255) NOT NULL,
	[updateDate] [datetime] NOT NULL,
	[restorer] [nvarchar](255) NOT NULL,
	[restoreDate] [datetime] NOT NULL,
 CONSTRAINT [PK_fileTypeSet] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[log]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[log](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DBServerIP] [nvarchar](40) NOT NULL,
	[monitorServerID] [int] NOT NULL,
	[monitorFileName] [nvarchar](255) NOT NULL,
	[monitorFileStatus] [nvarchar](255) NOT NULL,
	[monitorFilePath] [nvarchar](255) NOT NULL,
	[monitorFileType] [nvarchar](255) NOT NULL,
	[monitorFileSize] [nvarchar](255) NOT NULL,
	[monitorTime] [datetime] NOT NULL,
	[transferFlg] [smallint] NOT NULL,
	[backupServerGroupID] [int] NOT NULL,
	[backupServerID] [int] NOT NULL,
	[backupServerFileName] [nvarchar](50) NOT NULL,
	[backupServerFilePath] [nvarchar](50) NOT NULL,
	[backupServerFileType] [nvarchar](50) NOT NULL,
	[backupServerFileSize] [nvarchar](50) NOT NULL,
	[backupStartTime] [datetime] NOT NULL,
	[backupEndTime] [datetime] NOT NULL,
	[backupTime] [nvarchar](50) NOT NULL,
	[backupFlg] [smallint] NOT NULL,
	[copyStartTime] [datetime] NOT NULL,
	[copyEndTime] [datetime] NOT NULL,
	[copyTime] [nvarchar](255) NOT NULL,
	[copyFlg] [smallint] NOT NULL,
	[deleteFlg] [smallint] NOT NULL,
	[deleter] [nvarchar](255) NOT NULL,
	[deleteDate] [datetime] NOT NULL,
	[creater] [nvarchar](255) NOT NULL,
	[createDate] [datetime] NOT NULL,
	[updater] [nvarchar](255) NOT NULL,
	[updateDate] [datetime] NOT NULL,
	[restorer] [nvarchar](255) NOT NULL,
	[restoreDate] [datetime] NOT NULL,
 CONSTRAINT [PK__log__3213E83F1B0907CE] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[manualBackupServer]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[manualBackupServer](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DBServerIP] [nvarchar](40) NOT NULL,
	[serverIP] [varchar](50) NOT NULL,
	[account] [varchar](50) NOT NULL,
	[password] [varchar](50) NOT NULL,
	[drive] [varchar](50) NOT NULL,
	[startFile] [varchar](255) NOT NULL,
	[deleteFlg] [tinyint] NOT NULL,
	[deleter] [varchar](50) NULL,
	[deleteDate] [varchar](50) NULL,
	[creater] [varchar](50) NOT NULL,
	[createDate] [varchar](50) NOT NULL,
	[updater] [varchar](50) NOT NULL,
	[updateDate] [varchar](50) NOT NULL,
	[restorer] [varchar](50) NULL,
	[restoreDate] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[monitorBackupServer]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[monitorBackupServer](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DBServerIP] [nvarchar](40) NOT NULL,
	[monitorServerID] [int] NOT NULL,
	[backupServerGroupID] [int] NOT NULL,
	[deleteFlg] [smallint] NOT NULL,
	[deleter] [nvarchar](255) NOT NULL,
	[deleteDate] [datetime] NOT NULL,
	[creater] [nvarchar](255) NOT NULL,
	[createDate] [datetime] NOT NULL,
	[updater] [nvarchar](255) NOT NULL,
	[updateDate] [datetime] NOT NULL,
	[restorer] [nvarchar](255) NOT NULL,
	[restoreDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[monitorFileListen]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[monitorFileListen](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DBServerIP] [nvarchar](40) NOT NULL,
	[monitorServerID] [int] NOT NULL,
	[monitorFileName] [nvarchar](255) NOT NULL,
	[monitorType] [nvarchar](20) NOT NULL,
	[monitorServerIP] [nvarchar](40) NOT NULL,
	[sharePoint] [nvarchar](255) NOT NULL,
	[monitorLocalPath] [nvarchar](255) NOT NULL,
	[monitorFileRelativeDirectory] [nvarchar](500) NOT NULL,
	[monitorFileRelativeFullPath] [nvarchar](500) NOT NULL,
	[monitorFileLastWriteTime] [datetime] NOT NULL,
	[monitorFileSize] [nvarchar](255) NOT NULL,
	[monitorFileExtension] [nvarchar](255) NOT NULL,
	[monitorFileCreateTime] [datetime] NOT NULL,
	[monitorFileLastAccessTime] [datetime] NOT NULL,
	[monitorStatus] [nvarchar](20) NOT NULL,
	[monitorFileStartTime] [datetime] NOT NULL,
	[monitorFileEndTime] [datetime] NOT NULL,
	[deleteFlg] [smallint] NOT NULL,
	[deleter] [nvarchar](255) NOT NULL,
	[deleteDate] [datetime] NOT NULL,
	[creater] [nvarchar](255) NOT NULL,
	[createDate] [datetime] NOT NULL,
	[updater] [nvarchar](255) NOT NULL,
	[updateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[monitorServer]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[monitorServer](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DBServerIP] [nvarchar](40) NOT NULL,
	[monitorServerName] [nvarchar](255) NOT NULL,
	[monitorServerIP] [nvarchar](40) NOT NULL,
	[monitorSystem] [smallint] NOT NULL,
	[memo] [nvarchar](255) NOT NULL,
	[account] [nvarchar](255) NOT NULL,
	[password] [nvarchar](255) NOT NULL,
	[startFile] [nvarchar](255) NOT NULL,
	[monitorDrive] [nvarchar](255) NOT NULL,
	[monitorDriveP] [nvarchar](255) NOT NULL,
	[monitorMacPath] [nvarchar](255) NOT NULL,
	[monitorLocalPath] [nvarchar](255) NOT NULL,
	[copyInit] [smallint] NOT NULL,
	[deleteFlg] [smallint] NOT NULL,
	[deleter] [nvarchar](255) NOT NULL,
	[deleteDate] [datetime] NOT NULL,
	[creater] [nvarchar](255) NOT NULL,
	[createDate] [datetime] NOT NULL,
	[updater] [nvarchar](255) NOT NULL,
	[updateDate] [datetime] NOT NULL,
	[restorer] [nvarchar](255) NOT NULL,
	[restoreDate] [datetime] NOT NULL,
 CONSTRAINT [PK__monitorS__3213E83F0F975522] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[monitorServerFile]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[monitorServerFile](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DBServerIP] [nvarchar](40) NOT NULL,
	[monitorServerID] [int] NOT NULL,
	[monitorFileName] [nvarchar](255) NOT NULL,
	[monitorFileDirectory] [nvarchar](500) NOT NULL,
	[monitorFilePath] [nvarchar](500) NOT NULL,
	[monitorFileType] [nvarchar](255) NOT NULL,
	[monitorFileSize] [nvarchar](255) NOT NULL,
	[monitorStartTime] [datetime] NOT NULL,
	[monitorEndTime] [datetime] NOT NULL,
	[monitorFileStatus] [smallint] NOT NULL,
	[transferFlg] [smallint] NOT NULL,
	[transferNum] [int] NOT NULL,
	[deleteFlg] [smallint] NOT NULL,
	[deleter] [nvarchar](255) NOT NULL,
	[deleteDate] [datetime] NOT NULL,
	[creater] [nvarchar](255) NOT NULL,
	[createDate] [datetime] NOT NULL,
	[updater] [nvarchar](255) NOT NULL,
	[updateDate] [datetime] NOT NULL,
	[restorer] [nvarchar](255) NOT NULL,
	[restoreDate] [datetime] NOT NULL,
 CONSTRAINT [PK__monitorS__3213E83F1367E606] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[monitorServerFolder]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[monitorServerFolder](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DBServerIP] [nvarchar](40) NOT NULL,
	[monitorServerID] [int] NOT NULL,
	[monitorFileName] [nvarchar](255) NOT NULL,
	[monitorFilePath] [nvarchar](255) NOT NULL,
	[monitorFileType] [nvarchar](255) NOT NULL,
	[initFlg] [smallint] NOT NULL,
	[monitorFlg] [smallint] NOT NULL,
	[monitorStatus] [nvarchar](20) NOT NULL,
	[deleteFlg] [smallint] NOT NULL,
	[deleter] [nvarchar](255) NOT NULL,
	[deleteDate] [datetime] NOT NULL,
	[creater] [nvarchar](255) NOT NULL,
	[createDate] [datetime] NOT NULL,
	[updater] [nvarchar](255) NOT NULL,
	[updateDate] [datetime] NOT NULL,
	[restorer] [nvarchar](255) NOT NULL,
	[restoreDate] [datetime] NOT NULL,
 CONSTRAINT [PK__monitorS__3213E83F30F848ED] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[userInfo]    Script Date: 2014/05/28 14:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[userInfo](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[loginID] [nvarchar](40) NOT NULL,
	[password] [nvarchar](255) NOT NULL,
	[name] [nvarchar](255) NOT NULL,
	[mail] [nvarchar](255) NOT NULL,
	[mailFlg] [smallint] NOT NULL,
	[authorityFlg] [smallint] NOT NULL,
	[deleteFlg] [smallint] NOT NULL,
	[deleter] [nvarchar](255) NOT NULL,
	[deleteDate] [datetime] NOT NULL,
	[creater] [nvarchar](255) NOT NULL,
	[createDate] [datetime] NOT NULL,
	[updater] [nvarchar](255) NOT NULL,
	[updateDate] [datetime] NOT NULL,
	[restorer] [nvarchar](255) NOT NULL,
	[restoreDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET IDENTITY_INSERT [dbo].[userInfo] ON 

INSERT [dbo].[userInfo] ([id], [loginID], [password], [name], [mail], [mailFlg], [authorityFlg], [deleteFlg], [deleter], [deleteDate], [creater], [createDate], [updater], [updateDate], [restorer], [restoreDate]) VALUES (1, N'admin', N'admin', N'admin', N'admin@admin.com', 0, 0, 0, N'', CAST(0x0000000000000000 AS DateTime), N'admin', CAST(0x0000A27C00000000 AS DateTime), N'admin', CAST(0x0000A27C00000000 AS DateTime), N'', CAST(0x0000000000000000 AS DateTime))
SET IDENTITY_INSERT [dbo].[userInfo] OFF
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_DBServerIP]  DEFAULT ('') FOR [DBServerIP]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_backupServerName]  DEFAULT ('') FOR [backupServerName]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_backupServerIP]  DEFAULT ('') FOR [backupServerIP]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_memo]  DEFAULT ('') FOR [memo]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_account]  DEFAULT ('') FOR [account]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_password]  DEFAULT ('') FOR [password]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_startFile]  DEFAULT ('') FOR [startFile]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_ssbpath]  DEFAULT ('') FOR [ssbpath]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_deleteFlg]  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_deleter]  DEFAULT ('') FOR [deleter]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_deleteDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [deleteDate]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_creater]  DEFAULT ('') FOR [creater]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_createDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [createDate]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_updater]  DEFAULT ('') FOR [updater]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_updateDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [updateDate]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_restorer]  DEFAULT ('') FOR [restorer]
GO
ALTER TABLE [dbo].[backupServer] ADD  CONSTRAINT [DF_backupServer_restoreDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [restoreDate]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_DBServerIP]  DEFAULT ('') FOR [DBServerIP]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_backupServerGroupName]  DEFAULT ('') FOR [backupServerGroupName]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_monitorServerID]  DEFAULT ((0)) FOR [monitorServerID]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_memo]  DEFAULT ('') FOR [memo]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_deleteFlg]  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_deleter]  DEFAULT ('') FOR [deleter]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_deleteDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [deleteDate]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_creater]  DEFAULT ('') FOR [creater]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_createDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [createDate]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_updater]  DEFAULT ('') FOR [updater]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_updateDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [updateDate]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_restorer]  DEFAULT ('') FOR [restorer]
GO
ALTER TABLE [dbo].[backupServerGroup] ADD  CONSTRAINT [DF_backupServerGroup_restoreDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [restoreDate]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  CONSTRAINT [DF_backupServerGroupDetail_DBServerIP]  DEFAULT ('') FOR [DBServerIP]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  CONSTRAINT [DF_backupServerGroupDetail_backupServerGroupID]  DEFAULT ((0)) FOR [backupServerGroupID]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  CONSTRAINT [DF_backupServerGroupDetail_backupServerID]  DEFAULT ((0)) FOR [backupServerID]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  CONSTRAINT [DF_backupServerGroupDetail_deleter]  DEFAULT ('') FOR [deleter]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  CONSTRAINT [DF_backupServerGroupDetail_deleteDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [deleteDate]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  CONSTRAINT [DF_backupServerGroupDetail_creater]  DEFAULT ('') FOR [creater]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  CONSTRAINT [DF_backupServerGroupDetail_createDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [createDate]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  CONSTRAINT [DF_backupServerGroupDetail_updater]  DEFAULT ('') FOR [updater]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  CONSTRAINT [DF_backupServerGroupDetail_updateDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [updateDate]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  CONSTRAINT [DF_backupServerGroupDetail_restorer]  DEFAULT ('') FOR [restorer]
GO
ALTER TABLE [dbo].[backupServerGroupDetail] ADD  CONSTRAINT [DF_backupServerGroupDetail_restoreDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [restoreDate]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_DBServerIP]  DEFAULT ('') FOR [DBServerIP]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_monitorServerFolderName]  DEFAULT ('') FOR [monitorServerFolderName]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_monitorServerID]  DEFAULT ((0)) FOR [monitorServerID]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_exceptAttributeFlg1]  DEFAULT ('') FOR [exceptAttributeFlg1]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_exceptAttribute1]  DEFAULT ('') FOR [exceptAttribute1]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_exceptAttributeFlg2]  DEFAULT ('') FOR [exceptAttributeFlg2]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_exceptAttribute2]  DEFAULT ('') FOR [exceptAttribute2]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_exceptAttributeFlg3]  DEFAULT ('') FOR [exceptAttributeFlg3]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_exceptAttribute3]  DEFAULT ('') FOR [exceptAttribute3]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_systemFileFlg]  DEFAULT ((0)) FOR [systemFileFlg]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_hiddenFileFlg]  DEFAULT ((0)) FOR [hiddenFileFlg]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_attribute1]  DEFAULT ('') FOR [attribute1]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_attribute2]  DEFAULT ('') FOR [attribute2]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_attribute3]  DEFAULT ('') FOR [attribute3]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_deleteFlg]  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_deleter]  DEFAULT ('') FOR [deleter]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_deleteDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [deleteDate]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_creater]  DEFAULT ('') FOR [creater]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_createDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [createDate]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_updater]  DEFAULT ('') FOR [updater]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_updateDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [updateDate]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_restorer]  DEFAULT ('') FOR [restorer]
GO
ALTER TABLE [dbo].[fileTypeSet] ADD  CONSTRAINT [DF_fileTypeSet_restoreDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [restoreDate]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_DBServerIP]  DEFAULT ('') FOR [DBServerIP]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_monitorServerID]  DEFAULT ((0)) FOR [monitorServerID]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_monitorFileName]  DEFAULT ('') FOR [monitorFileName]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_monitorFileStatus]  DEFAULT ('') FOR [monitorFileStatus]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_monitorFilePath]  DEFAULT ('') FOR [monitorFilePath]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_monitorFileType]  DEFAULT ('') FOR [monitorFileType]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_monitorFileSize]  DEFAULT ('') FOR [monitorFileSize]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_monitorTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [monitorTime]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_transferFlg]  DEFAULT ((0)) FOR [transferFlg]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_backupServerGroupID]  DEFAULT ((0)) FOR [backupServerGroupID]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_backupServerID]  DEFAULT ((0)) FOR [backupServerID]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_backupServerFileName]  DEFAULT ('') FOR [backupServerFileName]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_backupServerFilePath]  DEFAULT ('') FOR [backupServerFilePath]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_backupServerFileType]  DEFAULT ('') FOR [backupServerFileType]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_backupServerFileSize]  DEFAULT ('') FOR [backupServerFileSize]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_backupStartTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [backupStartTime]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_backupEndTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [backupEndTime]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_backupTime]  DEFAULT ('') FOR [backupTime]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_backupFlg]  DEFAULT ((0)) FOR [backupFlg]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_copyStartTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [copyStartTime]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_copyEndTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [copyEndTime]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_copyTime]  DEFAULT ('') FOR [copyTime]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_copyFlg]  DEFAULT ((0)) FOR [copyFlg]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_deleteFlg]  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_deleter]  DEFAULT ('') FOR [deleter]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_deleteDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [deleteDate]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_creater]  DEFAULT ('') FOR [creater]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_createDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [createDate]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_updater]  DEFAULT ('') FOR [updater]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_updateDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [updateDate]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_restorer]  DEFAULT ('') FOR [restorer]
GO
ALTER TABLE [dbo].[log] ADD  CONSTRAINT [DF_log_restoreDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [restoreDate]
GO
ALTER TABLE [dbo].[manualBackupServer] ADD  CONSTRAINT [DF_manualBackupServer_deleteFlg]  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  CONSTRAINT [DF_monitorBackupServer_DBServerIP]  DEFAULT ('') FOR [DBServerIP]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  CONSTRAINT [DF_monitorBackupServer_monitorServerID]  DEFAULT ((0)) FOR [monitorServerID]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  CONSTRAINT [DF_monitorBackupServer_backupServerGroupID]  DEFAULT ((0)) FOR [backupServerGroupID]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  CONSTRAINT [DF_monitorBackupServer_deleter]  DEFAULT ('') FOR [deleter]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  CONSTRAINT [DF_monitorBackupServer_deleteDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [deleteDate]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  CONSTRAINT [DF_monitorBackupServer_creater]  DEFAULT ('') FOR [creater]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  CONSTRAINT [DF_monitorBackupServer_createDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [createDate]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  CONSTRAINT [DF_monitorBackupServer_updater]  DEFAULT ('') FOR [updater]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  CONSTRAINT [DF_monitorBackupServer_updateDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [updateDate]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  CONSTRAINT [DF_monitorBackupServer_restorer]  DEFAULT ('') FOR [restorer]
GO
ALTER TABLE [dbo].[monitorBackupServer] ADD  CONSTRAINT [DF_monitorBackupServer_restoreDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [restoreDate]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_DBServerIP]  DEFAULT ('') FOR [DBServerIP]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorServerID]  DEFAULT ((0)) FOR [monitorServerID]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorFileName]  DEFAULT ('') FOR [monitorFileName]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorType]  DEFAULT ('') FOR [monitorType]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorServerIP]  DEFAULT ('') FOR [monitorServerIP]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_sharePoint]  DEFAULT ('') FOR [sharePoint]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorLocalPath]  DEFAULT ('') FOR [monitorLocalPath]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorFileRelativeDirectory]  DEFAULT ('') FOR [monitorFileRelativeDirectory]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorFileRelativeFullPath]  DEFAULT ('') FOR [monitorFileRelativeFullPath]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorFileLastWriteTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [monitorFileLastWriteTime]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorFileSize]  DEFAULT ('') FOR [monitorFileSize]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorFileExtension]  DEFAULT ('') FOR [monitorFileExtension]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorFileCreateTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [monitorFileCreateTime]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorFileLastAccessTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [monitorFileLastAccessTime]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorStatus]  DEFAULT ('') FOR [monitorStatus]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorFileStartTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [monitorFileStartTime]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_monitorFileEndTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [monitorFileEndTime]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_deleteFlg]  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_deleter]  DEFAULT ('') FOR [deleter]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_deleteDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [deleteDate]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_creater]  DEFAULT ('') FOR [creater]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_createDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [createDate]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_updater]  DEFAULT ('') FOR [updater]
GO
ALTER TABLE [dbo].[monitorFileListen] ADD  CONSTRAINT [DF_monitorFileListen_updateDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [updateDate]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_DBServerIP]  DEFAULT ('') FOR [DBServerIP]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_monitorServerName]  DEFAULT ('') FOR [monitorServerName]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_monitorServerIP]  DEFAULT ('') FOR [monitorServerIP]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_monitorSystem]  DEFAULT ((0)) FOR [monitorSystem]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_memo]  DEFAULT ('') FOR [memo]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_account]  DEFAULT ('') FOR [account]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_password]  DEFAULT ('') FOR [password]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_startFile]  DEFAULT ('') FOR [startFile]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_monitorDrive]  DEFAULT ('') FOR [monitorDrive]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_monitorDriveP]  DEFAULT ('') FOR [monitorDriveP]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_monitorMacPath]  DEFAULT ('') FOR [monitorMacPath]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_monitorLocalPath]  DEFAULT ('') FOR [monitorLocalPath]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_copyinit]  DEFAULT ((0)) FOR [copyInit]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_deleteFlg]  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_deleter]  DEFAULT ('') FOR [deleter]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_deleteDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [deleteDate]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_creater]  DEFAULT ('') FOR [creater]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_createDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [createDate]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_updater]  DEFAULT ('') FOR [updater]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_updateDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [updateDate]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_restorer]  DEFAULT ('') FOR [restorer]
GO
ALTER TABLE [dbo].[monitorServer] ADD  CONSTRAINT [DF_monitorServer_restoreDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [restoreDate]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_DBServerIP]  DEFAULT ('') FOR [DBServerIP]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_monitorServerID]  DEFAULT ((0)) FOR [monitorServerID]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_monitorFileName]  DEFAULT ('') FOR [monitorFileName]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_monitorFileDirectory]  DEFAULT ('') FOR [monitorFileDirectory]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_monitorFilePath]  DEFAULT ('') FOR [monitorFilePath]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_monitorFileType]  DEFAULT ('') FOR [monitorFileType]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_monitorFileSize]  DEFAULT ('') FOR [monitorFileSize]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_monitorStartTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [monitorStartTime]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_monitorEndTime]  DEFAULT ('1900-01-01 00:00:00.000') FOR [monitorEndTime]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_monitorFileStatus]  DEFAULT ((0)) FOR [monitorFileStatus]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_transferFlg]  DEFAULT ((0)) FOR [transferFlg]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_transferNum]  DEFAULT ((0)) FOR [transferNum]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_deleteFlg]  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_deleter]  DEFAULT ('') FOR [deleter]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_deleteDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [deleteDate]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_creater]  DEFAULT ('') FOR [creater]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_createDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [createDate]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_updater]  DEFAULT ('') FOR [updater]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_updateDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [updateDate]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_restorer]  DEFAULT ('') FOR [restorer]
GO
ALTER TABLE [dbo].[monitorServerFile] ADD  CONSTRAINT [DF_monitorServerFile_restoreDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [restoreDate]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_DBServerIP]  DEFAULT ('') FOR [DBServerIP]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_monitorServerID]  DEFAULT ((0)) FOR [monitorServerID]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_monitorFileName]  DEFAULT ('') FOR [monitorFileName]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_monitorFilePath]  DEFAULT ('') FOR [monitorFilePath]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_monitorFileType]  DEFAULT ('') FOR [monitorFileType]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_initFlg]  DEFAULT ((0)) FOR [initFlg]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_monitorFlg]  DEFAULT ((0)) FOR [monitorFlg]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_monitorStatus]  DEFAULT ('') FOR [monitorStatus]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_deleteFlg]  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_deleter]  DEFAULT ('') FOR [deleter]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_deleteDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [deleteDate]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_creater]  DEFAULT ('') FOR [creater]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_createDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [createDate]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_updater]  DEFAULT ('') FOR [updater]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_updateDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [updateDate]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_restorer]  DEFAULT ('') FOR [restorer]
GO
ALTER TABLE [dbo].[monitorServerFolder] ADD  CONSTRAINT [DF_monitorServerFolder_restoreDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [restoreDate]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_loginID]  DEFAULT ('') FOR [loginID]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_password]  DEFAULT ('') FOR [password]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_name]  DEFAULT ('') FOR [name]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_mail]  DEFAULT ('') FOR [mail]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_mailFlg]  DEFAULT ((0)) FOR [mailFlg]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_authorityFlg]  DEFAULT ((0)) FOR [authorityFlg]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_deleteFlg]  DEFAULT ((0)) FOR [deleteFlg]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_deleter]  DEFAULT ('') FOR [deleter]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_deleteDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [deleteDate]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_creater]  DEFAULT ('') FOR [creater]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_createDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [createDate]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_updater]  DEFAULT ('') FOR [updater]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_updateDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [updateDate]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_restorer]  DEFAULT ('') FOR [restorer]
GO
ALTER TABLE [dbo].[userInfo] ADD  CONSTRAINT [DF_userInfo_restoreDate]  DEFAULT ('1900-01-01 00:00:00.000') FOR [restoreDate]
GO
USE [master]
GO
ALTER DATABASE [BudAllBackup] SET  READ_WRITE 
GO
