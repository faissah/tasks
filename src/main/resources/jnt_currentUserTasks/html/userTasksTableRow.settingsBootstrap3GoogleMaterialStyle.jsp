<c:forEach items="${moduleMap.currentList}" var="task" varStatus="status" begin="${moduleMap.begin}" end="${moduleMap.end}">
    <tr class="${status.count % 2 == 0 ? 'odd' : 'even'}">
        <td>
            <i id="iconTaskDisplayPlus_${task.identifier}" class="material-icons" style="vertical-align:middle"
               onclick="switchDisplay('${task.identifier}')">add
            </i>
            <i id="iconTaskDisplayMinus_${task.identifier}" class="material-icons" style="display:none;vertical-align:middle"
               onclick="switchDisplay('${task.identifier}')">remove
            </i>
            <strong>&nbsp;${fn:escapeXml(task.displayableName)}</strong>
            <c:if test="${not empty task.properties['targetNode'].node}">
                <c:set var="baseEdit" value="${url.baseEdit}"/>
                <c:set var="siteInLang" value="false"/>
                <c:set var="currentLocale">${currentResource.locale}</c:set>
                <c:forEach items="${task.properties['targetNode'].node.resolveSite.languages}" var="mapLang">
                    <c:if test="${currentLocale eq mapLang}">
                        <c:set var="siteInLang" value="true"/>
                    </c:if>
                </c:forEach>
                <c:if test="${not siteInLang}">
                    <c:set var="localeLength" value="${fn:length(fn:toUpperCase(currentResource.locale))}"/>
                    <c:set var="baseEdit"
                           value="${fn:substring(url.baseEdit,-1,fn:length(url.baseEdit)-localeLength)}${task.properties['targetNode'].node.resolveSite.defaultLanguage}"/>
                </c:if>
                <c:set value="${jcr:findDisplayableNodeInSite(task.properties['targetNode'].node, renderContext, task.properties['targetNode'].node.resolveSite)}" var="displayableNode"/>
                &nbsp;-&nbsp;
                <span>
                    <a href="<c:url value='${baseEdit}${displayableNode.path}.html'/>" target="_blank">
                            ${fn:escapeXml(task.properties["targetNode"].node.displayableName)}
                    </a>
                </span>
            </c:if>
            <c:set value="${jcr:findDisplayableNode(task, renderContext)}" var="displayableNode"/>
            <c:if test="${not empty displayableNode and not jcr:isNodeType(displayableNode, 'jnt:user')}">
                &nbsp;-&nbsp;
                <span>
                    <a href="<c:url value='${baseEdit}${displayableNode.path}.html'/>" target="_blank">
                            ${displayableNode.displayableName}
                    </a>
                </span>
            </c:if>
            <div class="taskdetail" id="taskdetail_${task.identifier}" style="display:none">
                <p>
                    <em><fmt:message key="label.createdBy"/>: ${task.properties['jcr:createdBy'].string},&nbsp;<fmt:message key="label.createdOn"/>&nbsp;<fmt:formatDate value="${task.properties['jcr:created'].date.time}" dateStyle="long" type="both"/></em>
                </p>
                <c:if test="${not empty task.properties['priority']}">
                    <p><fmt:message key="jnt_task.priority"/>:
                        <span><jcr:nodePropertyRenderer node="${task}" name="priority" renderer="resourceBundle"/></span>
                    </p>
                </c:if>
                <c:if test="${not empty task.properties['description']}">
                    <p>${task.properties['description'].string}</p>
                </c:if>
                <template:tokenizedForm>
                    <form id="tokenForm_${task.identifier}" name="tokenform_${task.identifier}" method="post" action="<c:url value='${url.basePreview}'/>${task.path}">
                    </form>
                </template:tokenizedForm>
                <c:set var="assignable" value="true"/>
                <c:if test="${not empty task.properties['candidates'] and task.properties['assigneeUserKey'].string ne user.path}">
                    <c:set var="assignable" value="false"/>
                    <c:set var="candidates" value=""/>
                    <c:forEach items="${task.properties['candidates']}" var="candidate">
                        <c:set var="candidates" value=" ${candidate.string} ${candidates} "/>
                    </c:forEach>
                    <c:set var="userKey" value="${user.path}"/>
                    <c:if test="${fn:contains(candidates, userKey)}">
                        <c:set var="assignable" value="true"/>
                    </c:if>
                    <c:if test="${not assignable}">
                        <c:set var="groups" value="${user:getUserMembership(user)}"/>
                        <c:forEach items="${groups}" var="x">
                            <c:if test="${fn:contains(candidates, x.key)}">
                                <c:set var="assignable" value="true"/>
                            </c:if>
                        </c:forEach>
                    </c:if>
                </c:if>
                <c:choose>
                    <c:when test="${task.properties.state.string == 'active' and task.properties['assigneeUserKey'].string ne user.path and assignable eq 'true'}">
                        <a class="btn btn-primary btn-sm" href="#" onclick="sendNewAssignee('${task.identifier}','${task.path}','${user.path}');return false;" title="assign to me">
                            <fmt:message key="label.actions.assigneToMe"/>
                        </a>
                    </c:when>
                    <c:when test="${task.properties.state.string == 'active' and task.properties['assigneeUserKey'].string eq user.path}">
                        <a class="btn btn-danger btn-sm" href="#" onclick="sendNewAssignee('${task.identifier}','${task.path}','');return false;" title="Unassign">
                            <fmt:message key="label.actions.unassign"/>
                        </a>
                        <a class="btn btn-success btn-sm" href="#" onclick="sendNewStatus('${task.identifier}','${task.path}','started');return false;" title="start">
                            <fmt:message key="label.actions.start"/>
                        </a>
                    </c:when>
                    <c:when test="${task.properties.state.string == 'started' and task.properties['assigneeUserKey'].string eq user.path}">
                        <a class="btn btn-danger btn-sm" href="#" onclick="sendNewAssignee('${task.identifier}','${task.path}','');return false;" title="Unassign">
                            <fmt:message key="label.actions.unassign"/>
                        </a>
                        <a class="btn btn-warning btn-sm" href="#" onclick="sendNewStatus('${task.identifier}','${task.path}','suspended');return false;" title="suspend">
                            <fmt:message key="label.actions.suspend"/>
                        </a>
                        <utility:setBundle basename="${task.properties['taskBundle'].string}" var="taskBundle"/>
                        <c:if test="${not empty task.properties['targetNode'].node}">
                            <c:set var="currentTaskNode" value="${jcr:findDisplayableNode(task.properties['targetNode'].node, renderContext)}"/>
                            <a class="btn btn-sm" target="_blank" href="<c:url value="${url.basePreview}${currentTaskNode.path}.html"/>">
                                <fmt:message key="label.preview"/>
                            </a>
                        </c:if>
                        <c:if test="${not empty task.properties['possibleOutcomes']}">
                            <c:forEach items="${task.properties['possibleOutcomes']}" var="outcome" varStatus="status">
                                <fmt:message bundle="${taskBundle}" var="outcomeLabel" key="${fn:replace(task.properties['taskName'].string,' ','.')}.${fn:replace(outcome.string,' ','.')}"/>
                                <c:if test="${fn:startsWith(outcomeLabel, '???')}"><fmt:message bundle="${taskBundle}" var="outcomeLabel" key="${fn:replace(task.properties['taskName'].string,' ','.')}.${fn:replace(fn:toLowerCase(outcome.string),' ','.')}"/></c:if>
                                <div>
                                    <a class="btn btn-primary btn-sm" href="#" onclick="sendNewStatus('${task.identifier}','${task.path}','finished','${outcome.string}');return false;" title="${outcome.string}">
                                            ${outcomeLabel}
                                    </a>
                                </div>
                            </c:forEach>
                        </c:if>
                        <c:if test="${empty task.properties['possibleOutcomes']}">
                            <c:set var="taskId" value="${task.identifier}"/>
                            <label class="checkbox" for="btnComplete-${taskId}">
                                <input class="checkbox completeTaskAction" taskPath="<c:url value='${url.basePreview}${currentNode.path}'/>" type="checkbox" id="btnComplete-${taskId}" onchange="sendNewStatus('${taskId}','${task.path}','finished')"/>
                                &nbsp;<fmt:message key="label.actions.completed"/>
                            </label>
                        </c:if>
                        <jcr:node var="taskData" path="${task.path}/taskData"/>
                        <c:if test="${not empty taskData}">
                            <template:module path="${task.path}/taskData" view="taskData"/>
                        </c:if>
                    </c:when>
                    <c:when test="${task.properties.state.string == 'finished'}">
                        &nbsp;<fmt:message key="label.actions.completed"/>
                    </c:when>
                    <c:when test="${task.properties.state.string == 'suspended' and task.properties['assigneeUserKey'].string eq user.path}">
                        <a class="btn btn-danger btn-small" href="#" onclick="sendNewAssignee('${task.identifier}','${task.path}','');return false;" title="Unassign">
                            <fmt:message key="label.actions.unassign"/>
                        </a>
                        <a class="btn btn-success btn-small" href="#" onclick="sendNewStatus('${task.identifier}','${task.path}','started');return false;" title="start">
                            <fmt:message key="label.actions.start"/>
                        </a>
                    </c:when>
                    <c:when test="${task.properties.state.string == 'canceled'}">
                    </c:when>
                </c:choose>
                <c:if test="${not empty task.properties['dueDate']}">
                    <div>
                        <a class="btn" href="<c:url value='${url.base}${task.path}.ics'/>" title="iCalendar">
                            <fmt:message key="label.actions.icalendar"/>
                        </a>
                    </div>
                </c:if>
            </div>
        </td>
        <c:if test="${dispAssignee}">
            <td headers="Assigned">
                <c:if test="${not empty task.properties['assigneeUserKey'].string}">
                    <jcr:node var="assigneeNode" path="${task.properties['assigneeUserKey'].string}"/>
                    ${assigneeNode.name}
                </c:if>
            </td>
        </c:if>
        <c:if test="${dispCreator}">
            <td headers="CreatedBy">
                    ${task.properties['jcr:createdBy'].string}
            </td>
        </c:if>
        <c:if test="${dispState}">
            <td class="center" headers="State">
                <c:if test="${task.properties.state.string eq 'started'}">
                    <span class="label label-warning">
                        <fmt:message key="jnt_task.state.${task.properties.state.string}"/>
                    </span>
                </c:if>
                <c:if test="${task.properties.state.string eq 'suspended'}">
                    <span class="label label-inverse">
                        <fmt:message key="jnt_task.state.${task.properties.state.string}"/>
                    </span>
                </c:if>
                <c:if test="${task.properties.state.string eq 'active'}">
                    <span class="label label-important">
                        <fmt:message key="jnt_task.state.${task.properties.state.string}"/>
                    </span>
                </c:if>
                <c:if test="${task.properties.state.string eq 'finished'}">
                    <span class="label label-success">
                        <fmt:message key="jnt_task.state.${task.properties.state.string}"/>
                    </span>
                </c:if>
            </td>
        </c:if>
        <c:choose>
            <c:when test="${dispDueDate}">
                <td>
                    <fmt:formatDate value="${task.properties['dueDate'].date.time}" dateStyle="medium" timeStyle="short" type="both"/>
                </td>
            </c:when>
            <c:when test="${dispLastModifiedDate}">
                <td>
                    <fmt:formatDate value="${task.properties['jcr:lastModified'].date.time}" dateStyle="medium" timeStyle="short" type="both"/>
                </td>
            </c:when>
        </c:choose>
    </tr>
</c:forEach>