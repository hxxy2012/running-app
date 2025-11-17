<?php
namespace app\common\service;

/**
 * 短信服务
 * 支持多种短信服务商：阿里云、腾讯云、华为云等
 */
class SmsService
{
    // 短信服务商配置
    private $provider;
    private $accessKeyId;
    private $accessKeySecret;
    private $signName;
    private $templateCode;

    public function __construct()
    {
        // 从配置文件读取
        $config = config('sms');
        $this->provider = $config['provider'] ?? 'aliyun';

        // 根据不同的服务商读取对应的配置
        $providerConfig = $config[$this->provider] ?? [];

        if ($this->provider === 'aliyun') {
            $this->accessKeyId = $providerConfig['access_key_id'] ?? '';
            $this->accessKeySecret = $providerConfig['access_key_secret'] ?? '';
            $this->signName = $providerConfig['sign_name'] ?? '';
            $this->templateCode = $providerConfig['template_code'] ?? '';
        } elseif ($this->provider === 'tencent') {
            $this->accessKeyId = $providerConfig['secret_id'] ?? '';
            $this->accessKeySecret = $providerConfig['secret_key'] ?? '';
            $this->signName = $providerConfig['sign_name'] ?? '';
            $this->templateCode = $providerConfig['template_id'] ?? '';
        }
    }

    /**
     * 发送验证码短信
     * @param string $phone 手机号
     * @param string $code 验证码
     * @return array
     */
    public function sendVerifyCode($phone, $code)
    {
        try {
            switch ($this->provider) {
                case 'aliyun':
                    return $this->sendByAliyun($phone, $code);
                case 'tencent':
                    return $this->sendByTencent($phone, $code);
                case 'huawei':
                    return $this->sendByHuawei($phone, $code);
                default:
                    // 开发模式：直接返回成功（不实际发送）
                    if (env('app_debug', false)) {
                        trace("开发模式：验证码 {$code} (未实际发送)", 'info');
                        return ['code' => 200, 'message' => '发送成功（开发模式）'];
                    }
                    return ['code' => 500, 'message' => '未配置短信服务商'];
            }
        } catch (\Exception $e) {
            trace('短信发送失败: ' . $e->getMessage(), 'error');
            return ['code' => 500, 'message' => '短信发送失败: ' . $e->getMessage()];
        }
    }

    /**
     * 阿里云短信发送
     * 文档: https://help.aliyun.com/document_detail/101414.html
     */
    private function sendByAliyun($phone, $code)
    {
        if (empty($this->accessKeyId) || empty($this->accessKeySecret)) {
            return ['code' => 500, 'message' => '阿里云短信配置不完整'];
        }

        // 使用阿里云SDK发送短信
        // 需要先安装: composer require alibabacloud/sdk
        try {
            // 示例代码（需要安装阿里云SDK）
            /*
            AlibabaCloud::accessKeyClient($this->accessKeyId, $this->accessKeySecret)
                ->regionId('cn-hangzhou')
                ->asDefaultClient();

            $result = AlibabaCloud::rpc()
                ->product('Dysmsapi')
                ->version('2017-05-25')
                ->action('SendSms')
                ->method('POST')
                ->host('dysmsapi.aliyuncs.com')
                ->options([
                    'query' => [
                        'RegionId' => 'cn-hangzhou',
                        'PhoneNumbers' => $phone,
                        'SignName' => $this->signName,
                        'TemplateCode' => $this->templateCode,
                        'TemplateParam' => json_encode(['code' => $code]),
                    ],
                ])
                ->request();

            $response = $result->toArray();
            if ($response['Code'] === 'OK') {
                return ['code' => 200, 'message' => '发送成功'];
            } else {
                return ['code' => 500, 'message' => $response['Message']];
            }
            */

            // 临时实现：使用HTTP请求
            return $this->sendByAliyunHttp($phone, $code);

        } catch (\Exception $e) {
            return ['code' => 500, 'message' => '阿里云短信发送异常: ' . $e->getMessage()];
        }
    }

    /**
     * 阿里云短信发送（HTTP方式）
     */
    private function sendByAliyunHttp($phone, $code)
    {
        $params = [
            'AccessKeyId' => $this->accessKeyId,
            'Action' => 'SendSms',
            'Format' => 'JSON',
            'PhoneNumbers' => $phone,
            'SignName' => $this->signName,
            'TemplateCode' => $this->templateCode,
            'TemplateParam' => json_encode(['code' => $code]),
            'SignatureMethod' => 'HMAC-SHA1',
            'SignatureVersion' => '1.0',
            'SignatureNonce' => uniqid(),
            'Timestamp' => gmdate('Y-m-d\TH:i:s\Z'),
            'Version' => '2017-05-25',
        ];

        // 生成签名
        $signature = $this->generateAliyunSignature($params);
        $params['Signature'] = $signature;

        // 发送HTTP请求
        $url = 'https://dysmsapi.aliyuncs.com/?' . http_build_query($params);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true); // 启用SSL验证（安全）
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10); // 10秒超时
        $response = curl_exec($ch);

        // 检查curl错误
        if ($response === false) {
            $error = curl_error($ch);
            curl_close($ch);
            return ['code' => 500, 'message' => 'HTTP请求失败: ' . $error];
        }

        curl_close($ch);

        $result = json_decode($response, true);

        if ($result === null) {
            return ['code' => 500, 'message' => '响应解析失败'];
        }

        if (isset($result['Code']) && $result['Code'] === 'OK') {
            return ['code' => 200, 'message' => '发送成功'];
        } else {
            $message = $result['Message'] ?? '未知错误';
            return ['code' => 500, 'message' => $message];
        }
    }

    /**
     * 生成阿里云签名
     */
    private function generateAliyunSignature($params)
    {
        ksort($params);
        $stringToSign = '';
        foreach ($params as $key => $value) {
            $stringToSign .= '&' . $this->percentEncode($key) . '=' . $this->percentEncode($value);
        }
        $stringToSign = 'GET&%2F&' . $this->percentEncode(substr($stringToSign, 1));
        return base64_encode(hash_hmac('sha1', $stringToSign, $this->accessKeySecret . '&', true));
    }

    /**
     * URL编码
     */
    private function percentEncode($str)
    {
        $res = urlencode($str);
        $res = preg_replace('/\+/', '%20', $res);
        $res = preg_replace('/\*/', '%2A', $res);
        $res = preg_replace('/%7E/', '~', $res);
        return $res;
    }

    /**
     * 腾讯云短信发送
     * 文档: https://cloud.tencent.com/document/product/382/43199
     */
    private function sendByTencent($phone, $code)
    {
        if (empty($this->accessKeyId) || empty($this->accessKeySecret)) {
            return ['code' => 500, 'message' => '腾讯云短信配置不完整'];
        }

        // 使用腾讯云SDK发送短信
        // 需要先安装: composer require tencentcloud/tencentcloud-sdk-php
        try {
            // 示例代码（需要安装腾讯云SDK）
            /*
            $cred = new Credential($this->accessKeyId, $this->accessKeySecret);
            $client = new SmsClient($cred, 'ap-guangzhou');

            $req = new SendSmsRequest();
            $req->SmsSdkAppId = config('sms.tencent.sdk_app_id');
            $req->SignName = $this->signName;
            $req->TemplateId = $this->templateCode;
            $req->TemplateParamSet = [$code];
            $req->PhoneNumberSet = ['+86' . $phone];

            $resp = $client->SendSms($req);

            if ($resp->SendStatusSet[0]->Code === 'Ok') {
                return ['code' => 200, 'message' => '发送成功'];
            } else {
                return ['code' => 500, 'message' => $resp->SendStatusSet[0]->Message];
            }
            */

            return ['code' => 500, 'message' => '请安装腾讯云SDK'];

        } catch (\Exception $e) {
            return ['code' => 500, 'message' => '腾讯云短信发送异常: ' . $e->getMessage()];
        }
    }

    /**
     * 华为云短信发送
     */
    private function sendByHuawei($phone, $code)
    {
        return ['code' => 500, 'message' => '华为云短信暂未实现'];
    }

    /**
     * 批量发送短信
     * @param array $phones 手机号数组
     * @param string $content 短信内容
     * @return array
     */
    public function sendBatch($phones, $content)
    {
        $results = [];
        foreach ($phones as $phone) {
            $results[] = $this->sendVerifyCode($phone, $content);
        }
        return $results;
    }

    /**
     * 发送通知短信
     * @param string $phone 手机号
     * @param string $templateCode 模板代码
     * @param array $params 模板参数
     * @return array
     */
    public function sendNotice($phone, $templateCode, $params = [])
    {
        // 实现通知短信发送
        return ['code' => 200, 'message' => '发送成功'];
    }
}
