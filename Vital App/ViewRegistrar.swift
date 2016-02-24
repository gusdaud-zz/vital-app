/* Importa classes usadas */
import UIKit
import AVFoundation
import Alamofire
import FBSDKCoreKit

/* View para captura de QRCode */
class ViewRegistrar: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    /* Variáveis usadas */
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var viewAutenticacao: ViewAutenticacao?
    
    /* View foi carregada */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            //Obtém referência à classe AVCaptureDevice para capturar o vídeo
            let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
            
            //Obtém a referência da instância do AVCaptureDeviceInput
            var input: AnyObject?
                try input = AVCaptureDeviceInput(device: captureDevice)
            
            //Inicializa o objeto de captura de sessão
            captureSession = AVCaptureSession()
            captureSession?.addInput(input as! AVCaptureInput)
            //Inicializa o objeto para captura de metadados e define o dispositivo de saída
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            //Define o delegate para usar a fila atual
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            //Adiciona o layer para visualizar o vídeo na tela atual
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            //Adiciona a caixa verde
            qrCodeFrameView = UIView()
            qrCodeFrameView?.layer.borderColor = UIColor.greenColor().CGColor
            qrCodeFrameView?.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView!)
            view.bringSubviewToFront(qrCodeFrameView!)
        } catch {
            print("Erro ao abrir a câmera")
            return
        }
    }
    
    /* View exibida */
    override func viewDidAppear(animated: Bool) {
        //Salva referência para aba de autenticação
        viewAutenticacao = (self.parentViewController as! UITabBarController).viewControllers![0] as? ViewAutenticacao
        //Inicia a captura do vídeo
        if (FBSDKAccessToken.currentAccessToken() != nil && appDelegate.Usuario != nil) {
            captureSession?.startRunning()
        } else {
            captureSession?.stopRunning()
        }
    }
    
    /* Registra o monitoramento */
    func registrarMonitoramento(MonitorID: String) {
        
        //Exibe a view de aguarde
        viewAutenticacao!.Aguarde.hidden = false
        
        //Chama o serviço REST
        let MeuID = appDelegate.Usuario!.valueForKey("id") as! NSString
        let MeuNome = appDelegate.Usuario!.valueForKey("first_name") as! NSString
        Alamofire.request(.POST, appDelegate.URL + "/servicos/monitor/registrardispositivo",
            parameters: ["MeuID": MeuID, "MeuNome": MeuNome, "MonitorID": MonitorID])
            .responseJSON { (response) in
                //Esconde a view de aguarde
                self.viewAutenticacao!.Aguarde.hidden = true
                //Exibe a mensagem
                if let JSON = response.result.value {
                    self.appDelegate.alerta("Vital", corpo: (JSON as! Bool ? "Registro realizado com sucesso" : "O dispositivo já estava registrado"))
                }
        }
    }
    
    /* Captura a saída */
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {

        //Verifica se o parâmetro com metadados existe e se contém pelo menos um objeto
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRectZero
            return
        }

        //Obtém o primeiro objeto com metadados e valida se é um QRCode
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            //Obtém as dimensões do código de barras e atualiza o quadro verde
            let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            qrCodeFrameView?.frame = barCodeObject.bounds;
            //Se tiver algum código embutido
            if metadataObj.stringValue != nil {
                var codigo = metadataObj.stringValue
                //Verifica se o código começa com Vital
                if (codigo.substringToIndex(codigo.startIndex.advancedBy(5)) == "VITAL") {
                    //Para o vídeo, muda para a primeira aba e chama a função para se comunicar com o servidor
                    codigo = codigo.substringFromIndex(codigo.startIndex.advancedBy(5))
                    let tababarController = self.parentViewController as! UITabBarController
                    tababarController.selectedIndex = 0
                    captureSession!.stopRunning()
                    registrarMonitoramento(codigo)
                }
            }
        }
    }

    /* Está faltando memória */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

