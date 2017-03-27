<!DOCTYPE html>
<%@ page language="java" contentType="text/html; charset=GBK" %>

<%@ page import="com.weaver.general.MD5"%>
<%@ page import="weaver.login.VerifyLogin"%>
<%@ page import="weaver.general.Util"%>
<%@ page import="weaver.conn.RecordSet"%>
<%
	request.setCharacterEncoding("UTF-8");
	response.setCharacterEncoding("UTF-8");
	/* 获取参数 */
	String username = Util.null2String(request.getParameter("username")).trim();
	String password = Util.null2String(request.getParameter("password")).trim();
	String userid = Util.null2String(request.getParameter("userid")).trim();
	
	String homePageId = "6";
	String salaryListPageId = "7";
	RecordSet rs = new RecordSet();
	/* 用户名校验 */
	if (username.indexOf(";") > -1 || username.indexOf("--") > -1 || username.indexOf(" ") > -1 || username.indexOf("'") > -1) {
		rs.writeLog("illegal sql statement input loginid:" + username);
		request.getRequestDispatcher("/mobilemode/appHomepageView.jsp?appHomepageId=" + homePageId + "&msg=illegal").forward(request, response);
		return;
	}

	MD5 md5 = new MD5();
	password = md5.getMD5ofStr(password);
	VerifyLogin vLogin = new VerifyLogin();
	request.setAttribute("userid", userid);
	request.setAttribute("username", username);
	//rs.writeLog(this.getClass() + "=== userid --> " + userid + "===");
	/* 管理员密码验证 */
	rs.execute("select loginid,password from HrmResourceManager where id = '" + userid + "'");
	String pwdTemp = "";
	if (rs.next()) {
		pwdTemp = Util.null2String(rs.getString("password"));
		if (pwdTemp.equals(password)) {
			request.getRequestDispatcher("/mobilemode/appHomepageView.jsp?appHomepageId=" + salaryListPageId).forward(request, response);
			return;
		}
	}
	/* 普通人员密码验证 */
	String[] strings = vLogin.checkUserPassM(username, password);
	if ("1".equals(strings[1])) {
		request.getRequestDispatcher("/mobilemode/appHomepageView.jsp?appHomepageId=" + salaryListPageId).forward(request, response);
	} else {
		request.getRequestDispatcher("/mobilemode/appHomepageView.jsp?appHomepageId=" + homePageId + "&msg=fail").forward(request,response);
	}

%>