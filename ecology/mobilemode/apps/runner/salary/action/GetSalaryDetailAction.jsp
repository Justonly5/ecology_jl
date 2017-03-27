<!DOCTYPE html>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="com.weaver.general.MD5"%>
<%@ page import="weaver.login.VerifyLogin"%>
<%@ page import="weaver.general.Util"%>
<%@ page import="weaver.conn.RecordSet"%>
<%@ page import="weaver.conn.RecordSetDataSource"%>
<%@ page import="net.sf.json.JSONArray"%>
<%@ page import="net.sf.json.JSONObject"%>
<%@ page import="weaver.hrm.User"%>
<%@ page import="weaver.hrm.UserManager"%>
<%@ page import="weaver.hrm.company.DepartmentComInfo"%>
<%@ page import="weaver.hrm.company.SubCompanyComInfo"%>
<%@ page import="weaver.hrm.resource.ResourceComInfo"%>
<%@ page import="com.weaver.formmodel.mobile.manager.MobileUserInit"%>
<%@ page import="com.weaver.formmodel.util.NumberHelper"%>
<%!
	/**
	 * 分页函数
	 * 
	 * @param querysql:传入的SQL
	 * @param orderby
	 * @param pageNo:页数
	 * @param pageSize:每页条数
	 * @return
	 * @author xiaozr2
	 * @version V1.01 2017
	 * 
	 */
	public String getPageSql(String querysql, String orderby, int pageNo, int pageSize) {
		RecordSet rs = new RecordSet();
		int currentpage = pageNo;
		int pagesize = pageSize;
		int iNextNum = currentpage * pageSize;
		String sql = "";
		if (rs.getDBType().equals("oracle")) {
			sql = "select rownum rownum_,t11.* from(" + querysql + " " + orderby
					+ " nulls last) t11 ";
			sql = "select * from (" + sql + ") t12 where rownum_ > " + (iNextNum - pagesize)
					+ " and rownum_ <= " + iNextNum;
		} else {
			sql = "select ROW_NUMBER() OVER (" + orderby + ") AS rownum_,* from (" + querysql
					+ ") t11 ";
			sql = "select * from (" + sql + ") t12 where rownum_> " + (iNextNum - pagesize)
					+ " and rownum_ <= " + iNextNum;
		}
		return sql;
	}
%>
<%
		request.setCharacterEncoding("UTF-8");
		response.setCharacterEncoding("UTF-8");
		JSONObject returnObj = new JSONObject();// 返回的JSON对象
		RecordSet rs = new RecordSet();
		rs.writeLog("=== Start GetSalaryDetail ===");
		RecordSetDataSource rsds = new RecordSetDataSource("E_HR");
		RecordSetDataSource rsds2 = new RecordSetDataSource("E_HR");
		RecordSetDataSource rsds3 = new RecordSetDataSource("E_HR");
		User user = MobileUserInit.getUser(request, response);
		String userid = Util.null2String(request.getParameter("userid"));
		if("".equals(userid)){
			userid = Util.null2String(request.getAttribute("userid"));
		}
		String username = Util.null2String(request.getAttribute("username"));
		if (user != null && "".equals(userid)) {
			userid = String.valueOf(user.getUID());
		}
		if (!"".equals(userid) && user == null) {
			UserManager userManager = new UserManager();
			user = userManager.getUserByUserIdAndLoginType(NumberHelper.string2Int(userid), "1");
		}
		if (user == null) {
			rs.writeLog("===== End Of Getting SalaryDetail Cause By User Is Null. =====");
			out.print("{\"status\":\"0\", \"errMsg\":\"用户失效,请请重新登录\"}");
			return;
		}
		/** 获取登陆人员信息 **/
		String loginid = user.getLoginid();
		if ("".equals(loginid)) {
			rs.writeLog("===== End Of Getting SalaryDetail Cause By LoginID Is Empty. =====");
			returnObj.put("datas", "[]");
			returnObj.put("totalSize", "0");
			returnObj.put("status", 0);
			returnObj.put("errMsg", "登陆用户异常!");
			response.reset();
			response.setCharacterEncoding("UTF-8");
			out.print(returnObj.toString());
			out.flush();			
			return;
		}
		/** 获取查询的月份 **/
		String month = Util.null2String(request.getParameter("month"));
		if("".equals(month)){
			returnObj.put("datas", "[]");
			returnObj.put("totalSize", "0");
			returnObj.put("status", 0);
			returnObj.put("errMsg", "查询月份为空!");
			rs.writeLog("==== End Of Getting SalaryDetail Cause By QueryMonth Is Empty! .===" );
			response.reset();
			response.setCharacterEncoding("UTF-8");
			out.print(returnObj.toString());
			out.flush();
			return;
		}
		//loginid = "00005"; // 测试用
		rs.writeLog("===== LoginId : " + loginid + " =======");
		rs.writeLog("===== QueryMonth : " + month + " =======");
		String lastname = user.getLastname();
		String jobtitle = user.getJobtitle();
		ResourceComInfo rc = null;
		DepartmentComInfo dc = null;
		SubCompanyComInfo sc = null;
		try {
			rc = new ResourceComInfo();
			dc = new DepartmentComInfo();
			sc = new SubCompanyComInfo();
		} catch (Exception e) {
			e.printStackTrace();
		}
		int departmentID = user.getUserDepartment();
		int subCompanyID = user.getUserSubCompany1();
		String departmentname = dc.getDepartmentname(departmentID + "");
		String subCompanyname = sc.getSubCompanyname(subCompanyID + "");
		//rs.writeLog("===== departmentID : " + departmentID + " =======");	
		//rs.writeLog("===== subCompanyID : " + subCompanyID + " =======");
		//rs.writeLog("===== departmentname : " + departmentname + " =======");	
		//rs.writeLog("===== subCompanyname : " + subCompanyname + " =======");
		/** 获取分页信息 **/
		int pageNo = Util.getIntValue(request.getParameter("pageNo"), 1);
		int pageSize = Util.getIntValue(request.getParameter("pageSize"), 10);
		String searchKey = Util.null2String(request.getParameter("searchKey"));
		
	
		/** 查询已发布工资列表SQL拼接 TODO**/
		StringBuilder sb = new StringBuilder();
		sb.append(" select c21.A0188 AS C21_A0188,c21.gz_ym AS month , a01.A0190 AS workid ,a0101 as name,");
		sb.append(" C21261 AS  joblevel ,c21.Dept_Code,A01102 AS cardno ,C21262 as joblevel2 ,");
		sb.append(" C21163 as basesalary,C21165 AS ksjb,convert(numeric(19,2),SFGZ) AS sfje,C21193 AS tax,");
		sb.append(" C21183 AS cqkk,C21221 AS cykk,C21169,C21171,C21185,C21186,C21189,C21273,C21274,k_month.a0188 AS K_MONTH_A0188,");
		sb.append(" convert(numeric(19,2),ABSENT_TIME/8) as kgts ,over_time3 AS pcjb,over_time4 AS zmjb,over_time5 as fdjb,");
		sb.append(" isnull(C21163,0)+isnull(C21165,0)+isnull(C21240,0) AS yfgz,");
		sb.append(" isnull(C21183,0)+isnull(C21241,0)+isnull(C21193,0)+isnull(C21221,0) AS kkhj,");
		sb.append(" LEAVE_TIME9+LEAVE_TIME10+K_MONTH15+LEAVE_TIME15+K_MONTH16+K_MONTH13+K_MONTH26+K_MONTH27 AS leavehour,");
		sb.append(" LATE_MIN+EARLY_MIN AS laterminus,convert(numeric(19,2),K_MONTH18/8) AS cqts,A01112 ");
		sb.append(" from a01 left join c21 on c21.a0188 = a01.a0188");
		sb.append(" left join k_month on k_month.a0188 = a01.a0188 AND c21.GZ_YM = k_month.GZ_YM");
		sb.append(" where c21.GZ_YM in(").append(month).append(")");
		sb.append(" AND a01.a0190 LIKE '").append(loginid).append("'+'%' ");		
		
		/** 查询加项详情SQL **/
		/** A01112 == 1 **/
		StringBuilder sb2 = new StringBuilder();
		//sb2.append(" if ISNULL(2,'')='1' ");
		//sb2.append(" begin");
		sb2.append(" SELECT '职等奖金' as GZAT23,convert(numeric(19,2),SUM(ISNULL(GZAT24,0))) as jt");
		sb2.append(" from C21,a01,GZBZ_8,GZAT2");
		sb2.append(" where ");
		sb2.append(" GZAT2.A0188=a01.A0188 AND GZBZ_83='加项' AND GZBZ_811='是' ");
		sb2.append(" AND GZAT2.GZAT22=GZBZ_8.GZBZ_81  AND   GZAT29='固定'");
		sb2.append(" AND C21.A0188=GZAT2.A0188  AND C21.GZ_YM=GZAT2.GZAT21 ");
		sb2.append(" AND GZAT22<>'1046'");
		sb2.append(" AND C21.GZ_YM= '").append(month).append("' AND A0190 like '").append(loginid).append("'+'%'");
		sb2.append(" GROUP BY GZAT2.A0188");
		sb2.append(" union");
		sb2.append(" SELECT ' 职业津贴' as zy,");
		sb2.append(" SUM(ISNULL(GZAT24,0)) as jt");
		sb2.append(" from C21,a01,GZBZ_8,GZAT2");
		sb2.append(" where");
		sb2.append(" GZAT2.A0188=a01.A0188  AND  GZBZ_83='加项' AND GZBZ_811='是'");
		sb2.append(" AND GZAT2.GZAT22=GZBZ_8.GZBZ_81  AND   GZAT29='固定'");
		sb2.append(" AND C21.A0188=GZAT2.A0188  AND C21.GZ_YM=GZAT2.GZAT21 ");
		sb2.append(" AND GZAT22='1046' ");
		sb2.append(" AND C21.GZ_YM= '").append(month).append("' AND A0190 like '").append(loginid).append("'+'%'");
		sb2.append(" GROUP BY GZAT2.A0188");
		sb2.append(" union");
		sb2.append(" SELECT GZAT23, ");
		sb2.append(" convert(numeric(19,2),SUM(GZAT24* case when patbm in ('0123','0124') then ISNULL(GZAT44,1)");		
		sb2.append(" when patbm in('0125','0127') then ISNULL(GZAT45,1)");
		sb2.append(" when patbm in('0128','0129') then ISNULL(GZAT47,1)");
		sb2.append(" when patbm in('0139','0140') then ISNULL(GZAT48,1)");
		sb2.append(" when patbm= '0130' then ISNULL(GZAT46,1) ELSE 1 end)) as jt");
		sb2.append(" from C21,a01,GZBZ_8 ,GZAT2");	
		sb2.append(" left join GZAT4 on GZAT2.A0188=GZAT4.A0188 AND  GZAT2.GZAT22=GZAT4.GZAT41 ");	
		sb2.append(" AND  GZAT21 between  DateName (YEAR, GZAT49)+DateName (MM,GZAT49)  AND  DateName (YEAR, GZAT410)+DateName (MM,GZAT410)");
		sb2.append(" where");	
		sb2.append(" GZAT2.A0188=a01.A0188  AND  GZBZ_83='加项' AND GZBZ_811='是'");
		sb2.append(" AND GZAT2.GZAT22=GZBZ_8.GZBZ_81");			
		sb2.append(" AND C21.A0188=GZAT2.A0188 AND GZAT29='浮动' AND C21.GZ_YM=GZAT2.GZAT21");	
		sb2.append(" AND C21.GZ_YM= '").append(month).append("' AND A0190 like '").append(loginid).append("'+'%'");
		sb2.append(" GROUP BY GZAT2.A0188,GZAT23,GZAT22");	
		//sb2.append(" END");		
		//sb2.append(" ELSE");
		//sb2.append(" BEGIN");
		/** Type == 2 **/
		StringBuilder sb3 = new StringBuilder();
		sb3.append(" SELECT GZAT23,");		
		sb3.append(" convert(numeric(19,2),SUM(GZAT24* case when patbm in ('0123','0124') then ISNULL(GZAT44,1)");						
		sb3.append(" when patbm in('0125','0127') then ISNULL(GZAT45,1)");						
		sb3.append(" when patbm in('0128','0129') then ISNULL(GZAT47,1)");						
		sb3.append(" when patbm in('0139','0140') then ISNULL(GZAT48,1)");	
		sb3.append(" when patbm= '0130' then ISNULL(GZAT46,1) ELSE 1 end)) as jt");
		sb3.append(" from C21,a01,GZBZ_8 ,GZAT2");	
		sb3.append(" left join GZAT4  on GZAT2.A0188=GZAT4.A0188 and  GZAT2.GZAT22=GZAT4.GZAT41");	
		sb3.append(" and GZAT21 between  DateName (YEAR, GZAT49)+DateName (MM,GZAT49)  AND  DateName (YEAR, GZAT410)+DateName (MM,GZAT410)");	
		sb3.append(" where");	
		sb3.append(" GZAT2.A0188=a01.A0188  and  GZBZ_83='加项' AND GZBZ_811='是'");	
		sb3.append(" AND GZAT2.GZAT22=GZBZ_8.GZBZ_81");	
		sb3.append(" AND C21.A0188=GZAT2.A0188  AND C21.GZ_YM=GZAT2.GZAT21");	
		sb3.append(" AND C21.GZ_YM= '").append(month).append("' AND A0190 like '").append(loginid).append("'+'%'");	
		sb3.append(" GROUP BY GZAT2.A0188,GZAT23 ,GZAT22");	
		sb3.append(" ORDER BY  GZAT22");
		// sb2.append(" END");
		
		/** 查询减项详情SQL **/ 
		StringBuilder sb4Minus = new StringBuilder();
		sb4Minus.append(" SELECT GZAT23, ");
		sb4Minus.append(" convert(numeric(19,2),SUM(GZAT24* case when patbm in('0123','0124') then ISNULL(GZAT44,1)");
		sb4Minus.append(" when patbm in('0125','0127') then ISNULL(GZAT45,1)");
		sb4Minus.append(" when patbm in('0128','0129') then ISNULL(GZAT47,1)");
		sb4Minus.append(" when patbm in('0139','0140') then ISNULL(GZAT48,1)");
		sb4Minus.append(" when patbm= '0130' then ISNULL(GZAT46,1) ELSE 1 end)) as jt");
		sb4Minus.append(" from C21,a01,GZBZ_8 ,GZAT2");
		sb4Minus.append(" left  join GZAT4  on GZAT2.A0188=GZAT4.A0188 and  GZAT2.GZAT22=GZAT4.GZAT41");
		sb4Minus.append(" and  GZAT21 between  DateName (YEAR, GZAT49)+DateName (MM,GZAT49)  AND  DateName (YEAR, GZAT410)+DateName (MM,GZAT410)");
		sb4Minus.append(" where ");
		sb4Minus.append(" GZAT2.A0188=a01.A0188  and  GZBZ_83='减项' AND GZBZ_811='是'");
		sb4Minus.append(" AND GZAT2.GZAT22=GZBZ_8.GZBZ_81");
		sb4Minus.append(" AND C21.A0188=GZAT2.A0188 AND C21.GZ_YM=GZAT2.GZAT21");
		sb4Minus.append(" AND C21.GZ_YM= '").append(month).append("' AND A0190 like '").append(loginid).append("'+'%'");	
		sb4Minus.append(" GROUP BY GZAT2.A0188,GZAT23 ,GZAT22");
		sb4Minus.append(" ORDER BY  GZAT22");
		
		JSONArray jsonArray = new JSONArray(); // 
		JSONObject jsonObj = new JSONObject();
		rs.writeLog("=== Start GetSalaryDetail ===");	
		/** 查询指定月份的工资详情 **/
		rsds.execute(sb.toString());
		String[] columnNames = rsds.getColumnName();
		String type = "";
		int totalSize = 0;
		while (rsds.next()) {
			String content_plus = "";
			String content_minus = "";
			for (String columnName : columnNames) {
				jsonObj.put(columnName, Util.null2String(rsds.getString(columnName)));
			}
			jsonObj.put("departmentname",departmentname);
			jsonObj.put("lastname",lastname);
			jsonObj.put("subCompanyname",subCompanyname);
			jsonObj.put("jobtitle",jobtitle);
			type = Util.null2String(rsds.getString("A01112"));
			/** 加项信息 **/
			if("1".equals(type)){
				rsds2.execute(sb2.toString());
				while(rsds2.next()){
					content_plus += "<li><span class='entryName'>" + Util.null2String(rsds2.getString("GZAT23"))+"</span><span class='entryContent'>" + Util.null2String(rsds2.getString("jt")) + "</span></li>";
				}
			}else{
				rsds2.execute(sb3.toString());
				while(rsds2.next()){
					content_plus += "<li><span class='entryName'>" + Util.null2String(rsds2.getString("GZAT23"))+"</span><span class='entryContent'>" + Util.null2String(rsds2.getString("jt")) + "</span></li>";
				}
			}
			jsonObj.put("content_plus",content_plus);
			/** 减项信息 **/
			rsds3.execute(sb4Minus.toString());
			while(rsds3.next()){
				content_minus += "<li><span class='entryName'>" + Util.null2String(rsds3.getString("GZAT23"))+"</span><span class='entryContent'>" + Util.null2String(rsds3.getString("jt")) + "</span></li>";
				//jsonObj.put("GZAT23_",Util.null2String(rsds3.getString("GZAT23")));
				//jsonObj.put("jt_",Util.null2String(rsds3.getString("jt")));
			}
			jsonObj.put("content_minus",content_minus);
			totalSize ++;
			jsonArray.add(jsonObj);
		}
		returnObj.put("datas", jsonArray);
		returnObj.put("totalSize", totalSize + "");
		response.reset();
		response.setCharacterEncoding("UTF-8");
		out.print(returnObj.toString());
		out.flush();
		out.close();
		//rs.writeLog("=== returnObj --> " + returnObj.toString() + "===");
		rs.writeLog("=== End GetSalaryDetail ===");
%>