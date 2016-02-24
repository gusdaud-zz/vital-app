/* Importa as classes usadas */
import UIKit
import Alamofire
import FBSDKLoginKit

/* View para autenticação */
class ViewAutenticacao: UIViewController, FBSDKLoginButtonDelegate {
    //Variáveis globais
    @IBOutlet weak var EnviarLocalizacao: UIButton!
    @IBOutlet weak var Aguarde: UIView!
    @IBOutlet weak var Login: FBSDKLoginButton!
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    /* Quando o usuário clica no botão de login */
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        //Verifica se algum erro ocorreu
        if ((error) != nil)
        {
            // Process error
        }
        //Verifica se o usuário cancelou
        else if result.isCancelled {
        }
        //Deu tudo certo
        else {
            //Inicia
            iniciar(true)
            //Valida se tem as permissões necessárias
            if result.grantedPermissions.contains("email")
            {
            }
        }
    }
    
    /* Quando o usuário clica no botão de logout */
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
        EnviarLocalizacao.hidden = true
    }
    
    /* Cadastra o dispositivo */
    func cadastrar() {
        Alamofire.request(.POST, appDelegate.URL + "/servicos/dispositivo/cadastrar",
            parameters: ["id": appDelegate.Usuario!.valueForKey("id")!, "pushToken": appDelegate.pushToken!])
            .responseJSON { (response) in
                //Exibe a mensagem
                if let JSON = response.result.value {
                    //Salva os dados do local storage
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setValue(self.appDelegate.Usuario!.valueForKey("id") as! String, forKey: "id")
                    defaults.setValue(JSON, forKey: "iotToken")
                    defaults.synchronize()
                    //Envia a localização
                    self.appDelegate.EnviarLocalizacao()
                }
        }
    }
    
    /* Envia manualmente a localização */
    @IBAction func EnviarLocalizacaoClique(sender: AnyObject) {
        appDelegate.sharedModel.alertarLocalizacao = true
        appDelegate.EnviarLocalizacao(true)
    }
        
    /* Inicia */
    func iniciar(cadastrar: Bool = false) {
        //Exibe o botão
        EnviarLocalizacao.hidden = false

        //Chama a função do Facebook para retornar os dados
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"first_name,id"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            //Se algum erro tiver ocorrido
            if ((error) != nil)
            {
                print("Erro")
            }
            else
            {
                self.appDelegate.Usuario = result
                if (cadastrar) { self.cadastrar() }
            }
        })
    }
    
    /* View carregada */
    override func viewDidLoad() {
        super.viewDidLoad()

        //Prepara o botão
        Login.readPermissions = ["public_profile"]
        Login.delegate = self
        Login.titleLabel?.text = ((FBSDKAccessToken.currentAccessToken() == nil)) ? " Entrar com Facebook" : " Desconectar"
        
        //Verifica se as variáveis estão salvas
        let defaults = NSUserDefaults.standardUserDefaults()
        if (defaults.stringForKey("id") == nil) || (defaults.stringForKey("iotToken") == nil) {
            let login = FBSDKLoginManager()
            login.logOut()
        }

        //Verifica se o usuário já está conectado no facebook
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            iniciar()
        }
    
    }

    /* Evento quando a memória está acabando */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}