/* Importa as classes usadas */
import Foundation
import CoreLocation
import UIKit
import Alamofire

/* Classe para gestão da geolocalização */
class LocationManagerBackground: NSObject, CLLocationManagerDelegate {
    
    /* Variáveis usadas */
    let IOT = "https://5xvfkk.internetofthings.ibmcloud.com/api/v0002/device/types/iPhone/devices/"
    var anotherLocationManager: CLLocationManager!
    var alertarLocalizacao = false
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var ultimaLatitude: Double?
    var ultimaLongitude: Double?

    /* Retorna se é IOS 8 ou superior */
    class var IS_IOS8_OR_LATER: Bool {
        let Device = UIDevice.currentDevice()
        let iosVersion = NSString(string: Device.systemVersion).doubleValue
        return iosVersion >= 8
    }
    /* Retorna se é IOS 9 ou superior */
    class var IS_IOS9_OR_LATER: Bool {
        let Device = UIDevice.currentDevice()
        let iosVersion = NSString(string: Device.systemVersion).doubleValue
        return iosVersion >= 9
    }
    
    /* Para acesso à instância desta classe */
    class var sharedManager : LocationManagerBackground {
        struct Static {
            static let instance : LocationManagerBackground = LocationManagerBackground()
        }
        return Static.instance
    }
    
    /* Classe sendo inicializada */
    private override init(){
        super.init()
    }
    
    /* Para iniciar a geolocalização quando houver mudança de local significativa */
    func startMonitoringLocation() {
        //Se a classe existir chama a função para parar de monitorar
        if (anotherLocationManager != nil) {
            anotherLocationManager.stopMonitoringSignificantLocationChanges()
        }
        //Cria uma nova instância da classe
        self.anotherLocationManager = CLLocationManager()
        anotherLocationManager.delegate = self
        anotherLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        anotherLocationManager.activityType = CLActivityType.OtherNavigation
        //Se for IOS 8 precisa da autorização
        if (LocationManagerBackground.IS_IOS8_OR_LATER) {
            anotherLocationManager.requestAlwaysAuthorization()
        }
        //Se for IOS 9 precisa ativar monitoração
        if #available(iOS 9.0, *) {
            anotherLocationManager.allowsBackgroundLocationUpdates = true
        }
        //Inicia a monitoração para mudanças de local significativas
        anotherLocationManager.startMonitoringSignificantLocationChanges()
    }
    
    /* Força a atualização */
    func forceUpdateLocation() {
        //Limpa as varíaveis
        ultimaLatitude = nil
        ultimaLongitude = nil
        //Solicita a localização
        if #available(iOS 9.0, *) {
            anotherLocationManager.requestLocation()
        } else {
            anotherLocationManager.startUpdatingLocation()
        }
    }
    
    /* Reinicia a geolocalização */
    func restartMonitoringLocation() {
        //Interrompe e reinicia
        anotherLocationManager.stopMonitoringSignificantLocationChanges()
        if (LocationManagerBackground.IS_IOS8_OR_LATER) {
            anotherLocationManager.requestAlwaysAuthorization()
        }
        if #available(iOS 9.0, *) {
            anotherLocationManager.allowsBackgroundLocationUpdates = true
        }
        anotherLocationManager.startMonitoringSignificantLocationChanges()
    }
    
    /* Inicia o monitoramento de raios */
    func iniciarMonitoramentoRaios() {
        var errorI: Int = 0
        while (anotherLocationManager.monitoredRegions.count < 3)
        {
            ++errorI
            if (errorI == 4) { break }
            criarRaios()
        }
        sleep(2);
    }
    
    /* Cria os raios */
    func criarRaios() {
        let Centro = anotherLocationManager.location!.coordinate
        let raio100 = CLCircularRegion(center: Centro, radius: 100, identifier: "RAIO100")
        anotherLocationManager.startMonitoringForRegion(raio100)
        let raio1000 = CLCircularRegion(center: Centro, radius: 100, identifier: "RAIO1000")
        anotherLocationManager.startMonitoringForRegion(raio1000)
        let raio10000 = CLCircularRegion(center: Centro, radius: 100, identifier: "RAIO10000")
        anotherLocationManager.startMonitoringForRegion(raio10000)
    }
    
    /* Saiu de uma região */
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        for monitored in anotherLocationManager.monitoredRegions
        {
            anotherLocationManager.stopMonitoringForRegion(monitored)
        }
        forceUpdateLocation()
        iniciarMonitoramentoRaios()
    }
    
    /* Erro do delegado */
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Erro ao atualizar geolocalização: " + error.debugDescription)
    }
    
    /* Método delegado */
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //Obtém o objeto de coordenadas
        let arrayOfLocation = locations as NSArray
        let location = arrayOfLocation.lastObject as! CLLocation
        let coordLatLon = location.coordinate
        //Salva a latitude e longitude
        let latitude: Double  = coordLatLon.latitude
        let longitude: Double = coordLatLon.longitude
        
        //Se for repetido não envia
        if (longitude == ultimaLongitude) && (latitude == ultimaLongitude) { return; }
        
        //Mostra no console
        print("Localização - lat \(String(format: "%.3f", latitude)), long \(String(format: "%.3f", longitude))")

        //Obtém os dados
        let defaults = NSUserDefaults.standardUserDefaults()
        if let id = defaults.stringForKey("id"), let token = defaults.stringForKey("iotToken") {
            
            //Codifica em Base64 o usuário e senha
            let credentialData = "use-token-auth:\(token)".dataUsingEncoding(NSUTF8StringEncoding)!
            let base64Credentials = credentialData.base64EncodedStringWithOptions([])
            let headers = ["Authorization": "Basic \(base64Credentials)"]
            let body = ["lat": latitude, "long": longitude]
            //Faz o request
            Alamofire.request(.POST, IOT + id + "/events/gps", parameters: body, headers: headers, encoding: .JSON).response { (response) in
                print(NSDate().formatted + " - Atualização enviada")
                if (self.alertarLocalizacao) { self.appDelegate.alerta("Vital", corpo: "Localização enviada") }
                self.alertarLocalizacao = false
                manager.startMonitoringSignificantLocationChanges()
                //Muda o badge
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0
            }
        }

        //Inicia o monitoramento por raios
        iniciarMonitoramentoRaios()

        
    }
    
}


