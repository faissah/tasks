<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="jcr" uri="http://www.jahia.org/tags/jcr" %>
<%@ taglib prefix="utility" uri="http://www.jahia.org/tags/utilityLib" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="functions" uri="http://www.jahia.org/tags/functions" %>
<%@ taglib prefix="query" uri="http://www.jahia.org/tags/queryLib" %>
<%@ taglib prefix="uiComponents" uri="http://www.jahia.org/tags/uiComponentsLib" %>

<c:set var="user" value="${uiComponents:getBindedComponent(currentNode, renderContext, 'j:bindedComponent')}"/>
    <c:if test="${empty user or not jcr:isNodeType(user, 'jnt:user')}">
        <jcr:node var="user" path="${renderContext.user.localPath}"/>
    </c:if>

<c:set value="" var="sql"/>
<c:if test="${currentNode.properties['filterOnAssignee'].string eq 'assignedToMe'}">
    <c:set value="${sql} and task.assigneeUserKey='${user.name}'" var="sql"/>
</c:if>

<c:if test="${currentNode.properties['filterOnAssignee'].string eq 'unassigned'}">
    <c:set value="${sql} and (task.assigneeUserKey is null or task.assigneeUserKey='')" var="sql"/>
</c:if>

<c:if test="${currentNode.properties['filterOnCreator'].string eq 'createdByMe'}">
    <c:set value="${sql} and task.['jcr:createdBy']='${user.name}'" var="sql"/>
</c:if>

<c:forEach items="${currentNode.properties['filterOnStates']}" var="stateValue" varStatus="status">
</c:forEach>
<c:forEach items="${currentNode.properties['filterOnStates']}" var="stateValue" varStatus="status">
    <c:if test="${status.first}">
        <c:set value="${sql} and (" var="sql"/>
    </c:if>
    <c:if test="${not status.first}">
        <c:set value="${sql} or " var="sql"/>
    </c:if>
    <c:set value="${sql}state='${stateValue.string}'" var="sql"/>
    <c:if test="${status.last}">
        <c:set value="${sql})" var="sql"/>
    </c:if>
</c:forEach>

<c:forEach items="${fn:split(currentNode.properties['filterOnTypes'].string,',')}" var="typeValue" varStatus="status">
    <c:if test="${status.first}">
        <c:set value="${sql} and (" var="sql"/>
    </c:if>
    <c:if test="${not status.first}">
        <c:set value="${sql} or " var="sql"/>
    </c:if>
    <c:set value="${sql}type='${typeValue}'" var="sql"/>
    <c:if test="${status.last}">
        <c:set value="${sql})" var="sql"/>
    </c:if>
</c:forEach>
<c:set value="select * from [jnt:task] as task where ${fn:substringAfter(sql, 'and')} order by task.['jcr:created'] desc" var="sql"/>

<query:definition var="listQuery" statement="${sql}" scope="request"/>
<c:set target="${moduleMap}" property="listQuery" value="${listQuery}" />
<c:set var="editable" value="false" scope="request"/>