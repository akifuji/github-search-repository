//
//  ViewController.swift
//  GitHubSearchRepository
//
//  Created by 藤田哲史 on 2017/06/20.
//  Copyright © 2017年 Akifumi Fujita. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Bond
import ReactiveKit

class ViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    let searchResults = MutableObservableArray<Repository>([])
    let alertMessages = PublishSubject<String, NoError>()
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        bindViewModel()
    }
    
    private func bindViewModel() {
        searchResults.bind(to: tableView) { searchResults, indexPath, tableView in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = searchResults[indexPath.row].name
            return cell
        }
        
        _ = alertMessages.observeNext {
            [weak self] message in
            let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { action in return }
            alertController.addAction(okAction)
            self?.present(alertController, animated: true, completion: nil)
            }.dispose(in: bag)
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let deadline = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            self.searchBySearchBarText()
        }
        return true
    }
    
    func searchBySearchBarText() {
        if let searchText = searchBar.text {
            Alamofire.request(Router.search(q: searchText, sort: "", order: "")).responseJSON { [unowned self] response in
                switch response.result {
                case .success:
                    let json = JSON(response.data)
                    if let message = json["message"] as? String {
                        return
                    }
                    if json["total_count"].intValue > 0 {
                        self.searchResults.removeAll()
                        for (_, json) in json["items"] {
                            let repository = Repository(json: json)
                            self.searchResults.append(repository)
                        }
                    }
                case .failure(let error):
                    let alertController = UIAlertController(title: "ERROR", message: error.localizedDescription, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default) { action in return }
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

