# 加密算法

### 使用JDK自带MessageDigest

```java
package com.bj58.bic.touchms.util;

import lombok.extern.slf4j.Slf4j;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

@Slf4j
public class SignUtil {

    public static final String sign(String converge) {

        try {
            MessageDigest md = MessageDigest.getInstance("MD5");

            md.reset();
            // 计算md5函数
            md.update(converge.getBytes());
            // digest()最后确定返回md5 hash值，返回值为8位字符串。因为md5 hash值是16位的hex值，实际上就是8位的字符  
            // BigInteger函数则将8位的字符串转换成16位hex值，用字符串来表示；得到字符串形式的hash值  
            String singStr = new BigInteger(1, md.digest()).toString(16);
            //BigInteger会把首位0去掉所以这里要补零
            return lowZeroPadding(singStr);
        } catch (NoSuchAlgorithmException e) {
            log.error("签名加密出错", e);
        }

        return "";
    }

    /**
     * 低位补零，最后必须是32位
     * @param singStr
     * @return
     */
    private static String lowZeroPadding(String singStr) {
        if (singStr.length() < 32){
            singStr = "0" + singStr;
            return lowZeroPadding(singStr);
        }
        return singStr;
    }
}

```


### 使用Spring自带的DigestUtils

```java
String md5Str = DigestUtils.md5DigestAsHex("原串".getBytes());
```


### 自己定义

```java
    /**
     * md5加密
     * @param data
     * @return
     * @throws NoSuchAlgorithmException
     */
    public static String md5(String data) throws NoSuchAlgorithmException {
        MessageDigest md = MessageDigest.getInstance("MD5");
        md.update(data.getBytes());
        StringBuffer buf = new StringBuffer();
        byte[] bits = md.digest();
        for(int i=0;i<bits.length;i++){
            int a = bits[i];
            if(a<0) a+=256;
            if(a<16) buf.append("0");
            buf.append(Integer.toHexString(a));
        }
        return buf.toString();
    }
```

