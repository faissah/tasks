/**
 * ==========================================================================================
 * =                   JAHIA'S DUAL LICENSING - IMPORTANT INFORMATION                       =
 * ==========================================================================================
 *
 *                                 http://www.jahia.com
 *
 *     Copyright (C) 2002-2017 Jahia Solutions Group SA. All rights reserved.
 *
 *     THIS FILE IS AVAILABLE UNDER TWO DIFFERENT LICENSES:
 *     1/GPL OR 2/JSEL
 *
 *     1/ GPL
 *     ==================================================================================
 *
 *     IF YOU DECIDE TO CHOOSE THE GPL LICENSE, YOU MUST COMPLY WITH THE FOLLOWING TERMS:
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 *
 *     2/ JSEL - Commercial and Supported Versions of the program
 *     ===================================================================================
 *
 *     IF YOU DECIDE TO CHOOSE THE JSEL LICENSE, YOU MUST COMPLY WITH THE FOLLOWING TERMS:
 *
 *     Alternatively, commercial and supported versions of the program - also known as
 *     Enterprise Distributions - must be used in accordance with the terms and conditions
 *     contained in a separate written agreement between you and Jahia Solutions Group SA.
 *
 *     If you are unsure which license is appropriate for your use,
 *     please contact the sales department at sales@jahia.com.
 */
package org.jahia.modules.tasks.rules;

import org.apache.commons.lang.StringUtils;
import org.drools.core.spi.KnowledgeHelper;
import org.jahia.ajax.gwt.client.data.definition.GWTJahiaNodePropertyValue;
import org.jahia.exceptions.JahiaException;
import org.jahia.registries.ServicesRegistry;
import org.jahia.services.content.JCRNodeWrapper;
import org.jahia.services.content.JCRPropertyWrapper;
import org.jahia.services.content.JCRSessionFactory;
import org.jahia.services.content.decorator.JCRGroupNode;
import org.jahia.services.content.decorator.JCRUserNode;
import org.jahia.services.content.rules.AddedNodeFact;
import org.jahia.services.sites.JahiaSite;
import org.jahia.services.tasks.Task;
import org.jahia.services.tasks.TaskService;
import org.jahia.services.usermanager.JahiaUser;
import org.jahia.services.usermanager.JahiaUserManagerService;
import org.jahia.services.workflow.WorkflowService;
import org.jahia.services.workflow.WorkflowVariable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.jcr.PropertyIterator;
import javax.jcr.RepositoryException;
import javax.jcr.Value;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

/**
 * @author rincevent
 * @since JAHIA 6.5
 *        Created : 5 janv. 2010
 */
public class Tasks {
    private transient static Logger logger = LoggerFactory.getLogger(Tasks.class);

    private static Tasks instance;
    private TaskService taskService;

    private Tasks() {
        super();
    }

    public static synchronized Tasks getInstance() {
        if (instance == null) {
            instance = new Tasks();
        }
        return instance;
    }

    public void createTask(String user, String title, String description, String priority, Date dueDate, String state,
                           KnowledgeHelper drools) throws RepositoryException {
        Task task = new Task(title, description);
        if (priority != null) {
            task.setPriority(Task.Priority.valueOf(priority));
        }
        task.setDueDate(dueDate);
        if (state != null) {
            task.setState(Task.State.valueOf(state));
        }
        taskService.createTask(task, user);
    }

    public void createTask(AddedNodeFact user, String title, String description, String priority, Date dueDate, String state,
                           KnowledgeHelper drools) throws RepositoryException {
        Task task = new Task(title, description);
        if (priority != null) {
            task.setPriority(Task.Priority.valueOf(priority));
        }
        task.setDueDate(dueDate);
        if (state != null) {
            task.setState(Task.State.valueOf(state));
        }
        taskService.createTask(task, (JCRUserNode) user.getNode());
    }

    public void createTask(String user, String title, String description, KnowledgeHelper drools)
            throws RepositoryException {
        createTask(user, title, description, null, null, null, drools);
    }

    public void createTask(AddedNodeFact user, String title, String description, KnowledgeHelper drools)
            throws RepositoryException {
        createTask(user, title, description, null, null, null, drools);
    }

    public void createTaskForGroupMembers(String group, String title, String description, KnowledgeHelper drools)
            throws RepositoryException {
        String siteKey = null;
        if (group.startsWith("/sites/")) {
            siteKey = StringUtils.substringBetween(group, "/sites/", "/");
        }
        if (group.indexOf('/') != -1) {
            group = StringUtils.substringAfterLast(group, "/");
        }
        taskService.createTaskForGroup(new Task(title, description), group, siteKey);
    }

    public void createTaskForGroupMembers(AddedNodeFact group, String title, String description, KnowledgeHelper drools)
            throws RepositoryException {
        taskService.createTaskForGroup(new Task(title, description), (JCRGroupNode) group.getNode());
    }

    public void setTaskService(TaskService taskService) {
        this.taskService = taskService;
    }

    public void assignTask(AddedNodeFact node, String username) {
        JCRUserNode user = ServicesRegistry.getInstance().getJahiaUserManagerService().lookupUserByPath(username);
        try {
            JCRNodeWrapper jcrNodeWrapper = node.getNode();
            String taskId = jcrNodeWrapper.getProperty("taskId").getString();
            String provider = jcrNodeWrapper.getProperty("provider").getString();
            JahiaUser realCurrentUser = node.getSession().getUser();
            JahiaUser root = JahiaUserManagerService.getInstance().lookupUserByPath("/users/root").getJahiaUser();
            JCRSessionFactory.getInstance().setCurrentUser(root);
            WorkflowService.getInstance().assignTask(taskId, provider, user != null ? user.getJahiaUser() : null);
            JCRSessionFactory.getInstance().setCurrentUser(realCurrentUser);
        } catch (RepositoryException e) {
            logger.error("cannot assign task", e);
        }
    }

    public void completeTask(AddedNodeFact node, JahiaUser user) {
        try {
            JCRNodeWrapper jcrNodeWrapper = node.getNode();
            String taskId = jcrNodeWrapper.getProperty("taskId").getString();
            String provider = jcrNodeWrapper.getProperty("provider").getString();
            String outcome = jcrNodeWrapper.getProperty("finalOutcome").getString();

            HashMap<String, Object> map = null;
            if (jcrNodeWrapper.hasNode("taskData")) {
                map = new HashMap<String, Object>();

                JCRNodeWrapper data = jcrNodeWrapper.getNode("taskData");
                PropertyIterator pi = data.getProperties();
                while (pi.hasNext()) {
                    JCRPropertyWrapper property = (JCRPropertyWrapper) pi.next();
                    if (!property.getDefinition().getDeclaringNodeType().getName().equals("nt:base") && !property.getDefinition().getName().equals("jcr:uuid")) {
                        if (property.isMultiple()) {
                            List<WorkflowVariable> values = new ArrayList<WorkflowVariable>();
                            for (Value value : property.getValues()) {
                                String s = value.getString();
                                if (StringUtils.isNotBlank(s)) {
                                    values.add(new WorkflowVariable(s, value.getType()));
                                }
                            }
                            map.put(property.getName(), values);
                        } else {
                            String s = property.getString();
                            if (StringUtils.isNotBlank(s)) {
                                map.put(property.getName(), new WorkflowVariable(s, property.getType()));
                            }
                        }
                    }
                }
            }

            WorkflowService.getInstance().completeTask(taskId, user, provider, outcome, map);
        } catch (RepositoryException e) {
            logger.error("cannot complete task", e);
        }
    }

}
