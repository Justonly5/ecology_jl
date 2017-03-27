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
		RecordSet rs = new RecordSet();
		rs.writeLog("====== Start GetSalaryList =====");
		RecordSetDataSource rsds = new RecordSetDataSource("E_HR");
		JSONObject returnObj = new JSONObject();// 返回的JSON对象
		/** 验证是否登录 **/
		String userid = Util.null2String(request.getParameter("userid"));		
		User user = MobileUserInit.getUser(request, response);
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
			rs.writeLog("=========== End of Getting salaryList cause by user is null ===========");
			//out.print("{\"status\":\"0\", \"errMsg\":\"用户失效,请请重新登录\"}");
			returnObj.put("datas","[]");
			returnObj.put("totalSize","0");
			response.reset();
			response.setCharacterEncoding("UTF-8");
			out.print(returnObj.toString());
			out.flush();
			out.close();
			return ;
		}
		/** 获取登陆人员信息 **/
		String loginid = user.getLoginid();
		//loginid = "00005"; // 测试用
		rs.writeLog("===== LoginId : " + loginid + " =======");
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
			rs.writeLog("======= ComInfo Initor Fail ======");
			returnObj.put("datas","[]");
			returnObj.put("totalSize","0");			
			response.reset();
			response.setCharacterEncoding("UTF-8");
			out.print(returnObj.toString());
			out.flush();
			out.close();
			return;			
		}
		String departmentID = rc.getDepartmentID();
		String subCompanyID = rc.getSubCompanyID();
		String departmentname = dc.getDepartmentname();
		String subCompanyname = sc.getSubCompanyname();
		/** 获取分页信息 **/
		int pageNo = Util.getIntValue(request.getParameter("pageNo"), 1);
		int pageSize = Util.getIntValue(request.getParameter("pageSize"), 10);
		String searchKey = Util.null2String(request.getParameter("searchKey"));
		
		/** 获取已发布的月份 **/
		/** 获取已发布的年月份(只取最近发布的月份) **/
		String month = "";
		String monthTable ="formtable_main_290";
		RecordSet rs2 = new RecordSet();
		rs.execute(" select year,month from " + monthTable + " order by id desc");
		if(rs.next()){
			String year = Util.null2String(rs.getString("year"));
			String monthids = Util.null2String(rs.getString("month"));
			String[] idArr = monthids.split(",");
			for(String id:idArr){
				rs2.execute("select monthstr from uf_month where id = " + id);
				if(rs2.next()){
					month += ("'" + year + Util.null2String(rs2.getString("monthstr")) + "'") + ",";
				}
			}
		}

		if("".equals(month)){
			rs.writeLog("======= End of Getting SalaryList Cause By SalaryMonth Is Empty =======");
			returnObj.put("datas", "[]");
			returnObj.put("totalSize", "0");
			response.reset();
			response.setCharacterEncoding("UTF-8");
			out.print(returnObj.toString());
			out.flush();
			out.close();
			return;				
		}
		month = month.substring(0, month.length() - 1);
		rs.writeLog("==== QueryMonth : " + month + "====");		
		/** 查询工资列表 **/
		StringBuilder sb = new StringBuilder();
		sb.append(" select c21.A0188 AS C21_A0188,c21.gz_ym AS month , a01.A0190 AS workid ,a0101 as name,");
		sb.append(" C21261 AS  joblevel ,c21.Dept_Code,A01102 AS cardno ,C21262 as joblevel2 ,");
		sb.append(" C21163 as basesalary,C21165 AS ksjb,convert(numeric(19,2),SFGZ) AS sfgz,C21193 AS tax,");
		sb.append(" C21183 AS cqkk,C21221 AS cykk,C21169,C21171,C21185,C21186,C21189,C21273,C21274,k_month.a0188 AS K_MONTH_A0188,");
		sb.append(" ABSENT_TIME/8 as kgts ,over_time3 AS pcjb,over_time4 AS zmjb,over_time5 as fdjb,");
		sb.append(" isnull(C21163,0)+isnull(C21165,0)+isnull(C21240,0) AS yfgz,");
		sb.append(" isnull(C21183,0)+isnull(C21241,0)+isnull(C21193,0)+isnull(C21221,0) AS kkhj,");
		sb.append(" LEAVE_TIME9+LEAVE_TIME10+K_MONTH15+LEAVE_TIME15+K_MONTH16+K_MONTH13+K_MONTH26+K_MONTH27  AS leavehour,");
		sb.append(" LATE_MIN+EARLY_MIN AS laterminus,K_MONTH18/8  AS cqts,A01112 ");
		sb.append(" from a01 left join c21 on c21.a0188 = a01.a0188");
		sb.append(" left join k_month on k_month.a0188 = a01.a0188 AND c21.GZ_YM = k_month.GZ_YM");
		sb.append(" where c21.GZ_YM in(").append(month).append(")");
		sb.append(" and a01.a0190 LIKE '").append(loginid).append("'+'%' ");		
		
		/** 搜索条件(月份搜索) **/
		String whereCondition = "";
		if (!"".equals(searchKey)) {
			whereCondition = " and c21.GZ_YM like '%" + searchKey + "%' ";
		}
			
		JSONArray jsonArray = new JSONArray(); // 
		JSONObject jsonObj = new JSONObject();
		//rs.writeLog("=== Start GetSalaryList ===");
		if ("".equals(loginid)) {
			rs.writeLog("========== End Of Getting SalaryList Cause By Loginid Is Empty! ======");
			returnObj.put("datas", "{}");
			returnObj.put("totalSize", "0");
			returnObj.put("status", 0);
			returnObj.put("errMsg", "登陆用户异常!");
			response.reset();
			response.setCharacterEncoding("UTF-8");
			out.print(returnObj.toString());
			out.flush();
			out.close();
			return;				
		}
		String sql = sb.append(whereCondition).toString();
		String querySqlPaging = getPageSql(sql, "order by month desc ", pageNo, pageSize);
		
		rsds.execute(querySqlPaging);
		String[] columnNames = rsds.getColumnName();
		while (rsds.next()) {
			for (String columnName : columnNames) {
				jsonObj.put(columnName, Util.null2String(rsds.getString(columnName)));
			}
			jsonObj.put("departmentname",departmentname);
			jsonObj.put("lastname",lastname);
			jsonObj.put("subCompanyname",subCompanyname);
			jsonObj.put("jobtitle",jobtitle);
			jsonArray.add(jsonObj);
		}
		
		/** 获取总记录数 **/
		String totalSql = "select count(1) as total from  (" + sql + ") t";
		rsds.execute(totalSql);
		String totalCount = "";
		if (rsds.next()) {
			totalCount = rsds.getString("total");
		}
		// if (jsonArray.size() == 0) {
			// jsonArray.add(new JSONObject());
			// returnObj.put("datas", jsonArray);
		// } else {
			// returnObj.put("datas", jsonArray);
		// }
		returnObj.put("datas", jsonArray);
		returnObj.put("totalSize", totalCount);
		response.reset();
		response.setCharacterEncoding("UTF-8");
		out.print(returnObj.toString());
		out.flush();
		out.close();
		//rs.writeLog("=== returnObj --> " + returnObj.toString() + "===");
		rs.writeLog("=== End GetSalaryList ===");
%>