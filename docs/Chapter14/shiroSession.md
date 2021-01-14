# shiro中出现不同请求session不同的现象

Shiro提供了三个默认实现：

DefaultSessionManager：DefaultSecurityManager使用的默认实现，用于JavaSE环境；

ServletContainerSessionManager：DefaultWebSecurityManager使用的默认实现，用于Web环境，其直接使用Servlet容器的会话；

DefaultWebSessionManager：用于Web环境的实现，可以替代ServletContainerSessionManager，自己维护着会话，直接废弃了Servlet容器的会话管理。



 

#### 遇到的坑：

在web环境下用ini文件配置shiro时，如果不指定SecurityManager时，
shiro会默认创建DefaultSecurityManager对象，这样会导致在web环境下，发不同的请求生成的session不同,导致登录功能失效。
因为DefaultSessionManager在源码中是和本地线程绑定的，而web环境中一个请求会创建一个线程，从而导致session都不同。

当使用DefaultWebSessionManager时，shiro中的session和web中的session是一致的。
而DefaultSessionManager的session和web中的session是不一致的。


#### 完整解决办法

ShiroConfiguration.java

```java

import com.fire.shiro.AuthRealm;
import com.fire.shiro.RedisManager;
import com.fire.shiro.RedisSessionDAO;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.mgt.SecurityManager;
import org.apache.shiro.spring.LifecycleBeanPostProcessor;
import org.apache.shiro.spring.security.interceptor.AuthorizationAttributeSourceAdvisor;
import org.apache.shiro.spring.web.ShiroFilterFactoryBean;
import org.apache.shiro.web.mgt.DefaultWebSecurityManager;
import org.apache.shiro.web.servlet.SimpleCookie;
import org.apache.shiro.web.session.mgt.DefaultWebSessionManager;
import org.springframework.aop.framework.autoproxy.DefaultAdvisorAutoProxyCreator;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.DependsOn;

@Slf4j
public abstract class ShiroConfiguration {

    abstract ShiroFilterFactoryBean shiroFilter(SecurityManager manager);

    // 配置自定义的权限登录器
    @Bean
    public AuthRealm authRealm() {
        AuthRealm authRealm = new AuthRealm();
        return authRealm;
    }

    // 配置核心安全事务管理器
    @Bean
    @ConditionalOnMissingBean
    public SecurityManager securityManager(AuthRealm authRealm, RedisSessionDAO redisSessionDAO) { //, EhCacheManager ehcacheManager
        DefaultWebSecurityManager manager = new DefaultWebSecurityManager();
        manager.setRealm(authRealm);
        // 缓存授权
        //manager.setCacheManager(ehcacheManager);

        DefaultWebSessionManager sessionManager = new DefaultWebSessionManager();
//        sessionManager.setGlobalSessionTimeout(7200000);
        sessionManager.setSessionDAO(redisSessionDAO);
        sessionManager.setSessionIdCookie(new SimpleCookie("ShiroSession"));

        manager.setSessionManager(sessionManager);
        return manager;
    }

    @Bean
    public RedisSessionDAO redisSessionDAO(RedisManager redisManager) {
        RedisSessionDAO redisSessionDAO = new RedisSessionDAO();
        redisSessionDAO.setRedisManager(redisManager);
//        redisSessionDAO.setRedisTemplate(redisTemplate);
        return redisSessionDAO;
    }

    @Bean
    public RedisManager redisManager(@Value("${session.redis.host}") final String redisHost,
                                     @Value("${session.redis.port}") final int redisPort,
                                     @Value("${session.redis.password}") final String redisPassword) {

        log.info("redisHost: {}, redisPort: {}, redisPassword: {}", redisHost, redisPort, redisPassword);
        RedisManager redisManager = new RedisManager();
        redisManager.setHost(redisHost);
        redisManager.setPort(redisPort);
        redisManager.setPassword(redisPassword);
        redisManager.setExpire(1800);
        return redisManager;
    }

    // 注解使用需要下面三个bean
    @Bean
    public LifecycleBeanPostProcessor lifecycleBeanPostProcessor() {
        return new LifecycleBeanPostProcessor();
    }

    @Bean
    @DependsOn("lifecycleBeanPostProcessor")
    public DefaultAdvisorAutoProxyCreator defaultAdvisorAutoProxyCreator() {
        DefaultAdvisorAutoProxyCreator creator = new DefaultAdvisorAutoProxyCreator();
        creator.setProxyTargetClass(true);
        return creator;
    }

    @Bean
    public AuthorizationAttributeSourceAdvisor authorizationAttributeSourceAdvisor(SecurityManager manager) {
        AuthorizationAttributeSourceAdvisor advisor = new AuthorizationAttributeSourceAdvisor();
        advisor.setSecurityManager(manager);
        return advisor;
    }
}

```

ProdShiroConfiguration.java
```java
import com.fire.shiro.AuthRealm;
import org.apache.shiro.cache.ehcache.EhCacheManager;
import org.apache.shiro.mgt.SecurityManager;
import org.apache.shiro.spring.web.ShiroFilterFactoryBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import javax.servlet.Filter;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

@Configuration
@Profile({"sandbox", "prod"})
public class ProdShiroConfiguration extends ShiroConfiguration {

    @Bean
    public ShiroFilterFactoryBean shiroFilter(SecurityManager manager) {
        ShiroFilterFactoryBean bean = new ShiroFilterFactoryBean();
        bean.setSecurityManager(manager);
        // 配置登录的url和登录成功的url
        bean.setLoginUrl("/login");
        bean.setUnauthorizedUrl("/illegal");

        Map<String, Filter> filters = new HashMap<>();
        bean.setFilters(filters);
        // 配置访问权限
        LinkedHashMap<String, String> filterChainDefinitionMap = new LinkedHashMap<>();
        filterChainDefinitionMap.put("/", "anon");
        filterChainDefinitionMap.put("/nonuser", "anon");
        filterChainDefinitionMap.put("/**", "authc");
        bean.setFilterChainDefinitionMap(filterChainDefinitionMap);

        return bean;
    }

    // 配置自定义的权限登录器
    @Bean
    public AuthRealm authRealm() {
        AuthRealm authRealm = new AuthRealm();
        return authRealm;
    }

    @Bean
    public EhCacheManager ehCacheCacheManager() {
        EhCacheManager ehCacheCacheManager = new EhCacheManager();
        return ehCacheCacheManager;
    }

    @Bean
    @ConditionalOnMissingBean
    public EhCacheManager shiroCacheManager(EhCacheManager ehCacheCacheManager) {
        EhCacheManager shiroCacheManager = new EhCacheManager();
        shiroCacheManager.setCacheManager(ehCacheCacheManager.getCacheManager());
        return shiroCacheManager;
    }


}

```


RedisSessionDAO.java

```java

import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.session.Session;
import org.apache.shiro.session.UnknownSessionException;
import org.apache.shiro.session.mgt.eis.AbstractSessionDAO;

import java.io.Serializable;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Slf4j
public class RedisSessionDAO extends AbstractSessionDAO {

    private RedisManager redisManager;
    /**
     * The Redis key prefix for the sessions
     */
    private String keyPrefix = "fire:";

    @Override
    public void update(Session session) throws UnknownSessionException {
        this.saveSession(session);
    }

    /**
     * save session
     *
     * @throws UnknownSessionException
     */
    private void saveSession(Session session) throws UnknownSessionException {
        if (session == null || session.getId() == null) {
            log.error("session or session id is null");
            return;
        }


        byte[] key = getByteKey(session.getId());
        byte[] value = SerializeUtils.serialize(session);
        session.setTimeout(redisManager.getExpire() * 1000);
        this.redisManager.set(key, value, redisManager.getExpire());


    }

    @Override
    public void delete(Session session) {

        if (session == null || session.getId() == null) {
            log.error("session or session id is null");
            return;
        }
        redisManager.del(this.getByteKey(session.getId()));

    }

    @Override
    public Collection<Session> getActiveSessions() {
        log.info("getActiveSessions session start");
        Set<Session> sessions = new HashSet<>();
        try {

            List<String> keys = redisManager.scan(this.keyPrefix + "*");
            if (keys != null && keys.size() > 0) {
                for (String key : keys) {
                    Session s = (Session) SerializeUtils.deserialize(redisManager.get(key.getBytes()));
                    sessions.add(s);
                }
            }
            log.info("getActiveSessions session end");

        } catch (Exception e) {
            log.error("getActiveSessions is error", e);
        }
        return sessions;
    }

    @Override
    protected Serializable doCreate(Session session) {

        Serializable sessionId = this.generateSessionId(session);
        this.assignSessionId(session, sessionId);
        this.saveSession(session);

        return sessionId;
    }

    @Override
    protected Session doReadSession(Serializable sessionId) {
        if (sessionId == null) {
            log.error("session id is null");
            return null;
        }

        Session s = (Session) SerializeUtils.deserialize(redisManager.get(this.getByteKey(sessionId)));

        return s;

    }

    /**
     * 获得byte[]型的key
     */
    private byte[] getByteKey(Serializable sessionId) {
        String preKey = this.keyPrefix + sessionId;
        return preKey.getBytes();
    }

    public void setRedisManager(RedisManager redisManager) {
        this.redisManager = redisManager;
        //初始化redisManager
        this.redisManager.init();
    }
}

```

