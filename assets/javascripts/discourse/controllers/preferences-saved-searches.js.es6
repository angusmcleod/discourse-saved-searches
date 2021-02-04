import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Controller.extend({
  saving: false,
  maxSavedSearches: 5,

  @discourseComputed("model.saved_searches")
  searchStrings() {
    console.log('searchstrings');
    let records = [];
    console.log(this.get("model.saved_searches"|| []));
    (this.get("model.saved_searches") || []).forEach((s) => {
      records.push({ query: s });
    });
    while (records.length < this.get("maxSavedSearches")) {
      records.push({ query: "" });
    }
    return records;
  },
    @discourseComputed("model.saved_tag_searches")
    tagSearchStrings() {
      console.log('tag searchstrings');
      let tag_records = [];
      console.log(this.get("model.saved_tag_searches"));
      (this.get("model.saved_tag_searches") || []).forEach((s) => {
        tag_records.push({ query: s });
      });
      while (tag_records.length < this.get("maxSavedSearches")) {
        tag_records.push({ query: "" });
      }
      return tag_records;
    },

  actions: {
    save() {
      console.log('save!');
      console.log(this.get("searchStrings"));
      console.log(this.get("tagSearchStrings"));
      this.setProperties({ saved: false, isSaving: true });

      const searches = this.get("searchStrings")
        .map((s) => {
          return s.query ? s.query : null;
        })
        .compact();

      this.set("model.saved_searches", searches);

      const tagSearches = this.get("tagSearchStrings")
        .map((s) => {
          return s.query ? s.query : null;
        })
        .compact();

      this.set("model.saved_tag_searches", tagSearches);

      return ajax("/saved_searches", {
        type: "PUT",
        dataType: "json",
        data: {
          searches: searches,
          tag_searches: tagSearches,
        },
      }).then((result, error) => {
        this.setProperties({ saved: true, isSaving: false });
        if (error) {
          popupAjaxError(error);
        }
      });
    },
  },
});
