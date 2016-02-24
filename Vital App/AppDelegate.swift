/* Importa as classes usadas */
import UIKit
import Alamofire
import CoreLocation
import FBSDKCoreKit

/* Classe principal da aplicação */
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /* Variáveis globais */
    var window: UIWindow?
    var pushToken: String?
    var Usuario: AnyObject?
    var sharedModel: LocationManagerBackground!
    
    /* Url */
    //var URL = "http://192.168.0.109:8080"
    var URL = "http://vital-app.mybluemix.net"
    
    
    /* Envia a localização */
    func EnviarLocalizacao(forcar: Bool = true) {
        self.sharedModel.forceUpdateLocation()
    }
    
    /* Assim que a aplicação é iniciada */
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        //Registra o push
        if (LocationManagerBackground.IS_IOS8_OR_LATER) {
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge], categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
            UIApplication.sharedApplication().registerForRemoteNotifications()
        }
        
        //Inicia o gerenciador do GPS
        self.sharedModel = LocationManagerBackground.sharedManager
        
        //Valida as permissões
        if (application.backgroundRefreshStatus == UIBackgroundRefreshStatus.Denied) {
            alerta("Vital", corpo: "Esta aplicação requer a funcionalidade para ser executada em plano de fundo. Para ativar vá em Configurações > Geral > Atualização em plano de fundo")
        } else if (application.backgroundRefreshStatus == UIBackgroundRefreshStatus.Restricted) {
            alerta("Vital", corpo: "Esta aplicação não vai funcionar pois a funcionalidade de atualização está desativada")
        } else {
            //Começa a monitorar a geolocalização
            if (launchOptions?[UIApplicationLaunchOptionsLocationKey] != nil) {
                self.sharedModel.startMonitoringLocation()
            }
        }
        
        //Chama a função do facebook
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    /* Recebeu um push */
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        let state: UIApplicationState = application.applicationState
        if state == .Active {
            alerta("Notificação", corpo: userInfo["aps"]!["alert"] as! String)
            completionHandler(UIBackgroundFetchResult.NoData)
        }
    }
    /* Push registrado */
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        //Filtra o código do token
        let trimEnds = {deviceToken.description.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"))}
        pushToken = { trimEnds().stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch)}()
        //Salva os dados do local storage
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(pushToken!, forKey: "pushToken")
        defaults.synchronize()
        print("Identificador de push: \(pushToken!)")
    }
    /* Push não pode ser registrado */
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        //Erro ao obter o token do push
        print("Não foi possível obter o token para o push, erro: %@", error)
    }
    
    /* Callback quando uma URL é chamada */
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    /* Exibe um alerta */
    func alerta(titulo: String, corpo: String) {
        let alerta = UIAlertView(title: titulo, message: corpo, delegate: nil, cancelButtonTitle: "OK")
        alerta.show()
        
    }
    
    /* Aplicação está para ser ativada */
    func applicationDidBecomeActive(application: UIApplication) {
        //Começa a monitorar
        self.sharedModel.startMonitoringLocation()
    }
    
    /* Outras notificações */
    func applicationDidEnterBackground(application: UIApplication) { }
    func applicationWillEnterForeground(application: UIApplication) { }
    func applicationWillTerminate(application: UIApplication) { }
    func applicationWillResignActive(application: UIApplication) { }
}

