//
//  MapViewController.swift
//  VirtualAssistantforiOSwithWatsonBOKEI
//
//  Created by DanielMandea on 6/10/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit
import NMAKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: NMAMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        mapView.useHighResolutionMap = true
        mapView.zoomLevel = 13.2
        mapView.set(geoCenter: NMAGeoCoordinates(latitude: 49.258867, longitude: -123.008046), animation: .linear)
        mapView.copyrightLogoPosition = NMALayoutPosition.bottomCenter
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
