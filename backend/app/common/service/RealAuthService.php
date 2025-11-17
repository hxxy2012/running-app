<?php
namespace app\common\service;

/**
 * 实名认证服务
 * 支持阿里云、腾讯云等实名认证服务
 */
class RealAuthService
{
    // 服务商配置
    private $provider;
    private $accessKeyId;
    private $accessKeySecret;

    public function __construct()
    {
        $config = config('realauth');
        $this->provider = $config['provider'] ?? 'aliyun';

        // 根据不同的服务商读取对应的配置
        $providerConfig = $config[$this->provider] ?? [];

        if ($this->provider === 'aliyun') {
            $this->accessKeyId = $providerConfig['access_key_id'] ?? '';
            $this->accessKeySecret = $providerConfig['access_key_secret'] ?? '';
        } elseif ($this->provider === 'tencent') {
            $this->accessKeyId = $providerConfig['secret_id'] ?? '';
            $this->accessKeySecret = $providerConfig['secret_key'] ?? '';
        }
    }

    /**
     * 实名认证
     * @param string $realName 真实姓名
     * @param string $idCard 身份证号
     * @return array
     */
    public function verify($realName, $idCard)
    {
        try {
            // 基础验证
            if (empty($realName) || empty($idCard)) {
                return ['code' => 400, 'message' => '姓名或身份证号不能为空'];
            }

            // 身份证号格式验证
            if (!$this->validateIdCard($idCard)) {
                return ['code' => 400, 'message' => '身份证号格式不正确'];
            }

            // 调用对应服务商API
            switch ($this->provider) {
                case 'aliyun':
                    return $this->verifyByAliyun($realName, $idCard);
                case 'tencent':
                    return $this->verifyByTencent($realName, $idCard);
                default:
                    // 开发模式：直接返回成功（不实际验证）
                    if (env('app_debug', false)) {
                        trace("开发模式：实名认证 {$realName} / {$idCard} (未实际验证)", 'info');
                        return [
                            'code' => 200,
                            'message' => '认证成功（开发模式）',
                            'data' => [
                                'verified' => true,
                                'name' => $realName,
                                'id_card' => $this->maskIdCard($idCard)
                            ]
                        ];
                    }
                    return ['code' => 500, 'message' => '未配置实名认证服务商'];
            }
        } catch (\Exception $e) {
            trace('实名认证失败: ' . $e->getMessage(), 'error');
            return ['code' => 500, 'message' => '认证失败: ' . $e->getMessage()];
        }
    }

    /**
     * 阿里云实名认证
     * 文档: https://help.aliyun.com/document_detail/127909.html
     */
    private function verifyByAliyun($realName, $idCard)
    {
        if (empty($this->accessKeyId) || empty($this->accessKeySecret)) {
            return ['code' => 500, 'message' => '阿里云实名认证配置不完整'];
        }

        // 使用阿里云身份证实人认证API
        try {
            // 示例代码（需要安装阿里云SDK）
            /*
            use AlibabaCloud\SDK\Cloudauth\V20190307\Cloudauth;
            use AlibabaCloud\SDK\Cloudauth\V20190307\Models\VerifyMaterialRequest;

            $config = new Config([
                'accessKeyId' => $this->accessKeyId,
                'accessKeySecret' => $this->accessKeySecret,
                'endpoint' => 'cloudauth.aliyuncs.com',
            ]);

            $client = new Cloudauth($config);
            $request = new VerifyMaterialRequest([
                'name' => $realName,
                'identificationNumber' => $idCard,
            ]);

            $response = $client->verifyMaterial($request);

            if ($response->body->success) {
                return [
                    'code' => 200,
                    'message' => '认证成功',
                    'data' => [
                        'verified' => true,
                        'name' => $realName,
                        'id_card' => $this->maskIdCard($idCard)
                    ]
                ];
            } else {
                return ['code' => 400, 'message' => '认证失败'];
            }
            */

            return ['code' => 500, 'message' => '请安装阿里云SDK并配置实名认证服务'];

        } catch (\Exception $e) {
            return ['code' => 500, 'message' => '阿里云实名认证异常: ' . $e->getMessage()];
        }
    }

    /**
     * 腾讯云实名认证
     * 文档: https://cloud.tencent.com/document/product/1007/31816
     */
    private function verifyByTencent($realName, $idCard)
    {
        if (empty($this->accessKeyId) || empty($this->accessKeySecret)) {
            return ['code' => 500, 'message' => '腾讯云实名认证配置不完整'];
        }

        // 使用腾讯云人脸核身API
        try {
            // 示例代码（需要安装腾讯云SDK）
            /*
            use TencentCloud\Common\Credential;
            use TencentCloud\Faceid\V20180301\FaceidClient;
            use TencentCloud\Faceid\V20180301\Models\IdCardVerificationRequest;

            $cred = new Credential($this->accessKeyId, $this->accessKeySecret);
            $client = new FaceidClient($cred, 'ap-guangzhou');

            $req = new IdCardVerificationRequest();
            $req->IdCard = $idCard;
            $req->Name = $realName;

            $resp = $client->IdCardVerification($req);

            if ($resp->Result === '0') {
                return [
                    'code' => 200,
                    'message' => '认证成功',
                    'data' => [
                        'verified' => true,
                        'name' => $realName,
                        'id_card' => $this->maskIdCard($idCard)
                    ]
                ];
            } else {
                return ['code' => 400, 'message' => '认证失败'];
            }
            */

            return ['code' => 500, 'message' => '请安装腾讯云SDK并配置实名认证服务'];

        } catch (\Exception $e) {
            return ['code' => 500, 'message' => '腾讯云实名认证异常: ' . $e->getMessage()];
        }
    }

    /**
     * 验证身份证号格式
     */
    private function validateIdCard($idCard)
    {
        // 18位身份证号正则
        $pattern = '/^[1-9]\d{5}(18|19|20)\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\d{3}[0-9Xx]$/';
        return preg_match($pattern, $idCard) === 1;
    }

    /**
     * 身份证号脱敏
     */
    private function maskIdCard($idCard)
    {
        if (strlen($idCard) === 18) {
            return substr($idCard, 0, 6) . '********' . substr($idCard, -4);
        }
        return $idCard;
    }

    /**
     * OCR识别身份证
     * @param string $imagePath 身份证图片路径
     * @param string $side front-正面, back-反面
     * @return array
     */
    public function ocrIdCard($imagePath, $side = 'front')
    {
        try {
            switch ($this->provider) {
                case 'aliyun':
                    return $this->ocrIdCardByAliyun($imagePath, $side);
                case 'tencent':
                    return $this->ocrIdCardByTencent($imagePath, $side);
                default:
                    return ['code' => 500, 'message' => '未配置OCR服务商'];
            }
        } catch (\Exception $e) {
            return ['code' => 500, 'message' => 'OCR识别失败: ' . $e->getMessage()];
        }
    }

    /**
     * 阿里云OCR识别
     */
    private function ocrIdCardByAliyun($imagePath, $side)
    {
        // 实现阿里云OCR识别
        return ['code' => 500, 'message' => '请安装阿里云OCR SDK'];
    }

    /**
     * 腾讯云OCR识别
     */
    private function ocrIdCardByTencent($imagePath, $side)
    {
        // 实现腾讯云OCR识别
        return ['code' => 500, 'message' => '请安装腾讯云OCR SDK'];
    }
}
